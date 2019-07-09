#!/bin/bash
# shipped to a remote virtual machine to deploy sample-configuration there
set -ex

cd "$HOME"
if [ ! -d sample-configuration ]; then
    git clone https://github.com/libero/sample-configuration --recurse-submodules
    cd sample-configuration
    git checkout "${BRANCH_NAME}"
else
    cd sample-configuration
    git checkout master
    git pull origin master
    git checkout "${BRANCH_NAME}"
    git pull origin "${BRANCH_NAME}"
    git submodule update --init
fi

if [ ! -f .env ]; then
    cp .env.dist .env
fi

for environment_variable_name in BROWSER_GTM_ID ENVIRONMENT_NAME PUBLIC_PORT_HTTP PUBLIC_PORT_HTTPS; do
    sed -i -e "s/^${environment_variable_name}=.*$/${environment_variable_name}=${!environment_variable_name}/g" .env
done

echo "Setting revisions of applications"
declare -A revisions=()
revisions[CONTENT_STORE]="$REVISION_CONTENT_STORE"
revisions[BROWSER]="$REVISION_BROWSER"
revisions[DUMMY_API]="$REVISION_DUMMY_API"
revisions[JATS_INGESTER]="$REVISION_JATS_INGESTER"
revisions[PATTERN_LIBRARY]="$REVISION_PATTERN_LIBRARY"
revisions[SEARCH]="$REVISION_SEARCH"
for application in "${!revisions[@]}"
do
    if [ -n "${revisions[$application]}" ]; then
        sed -i -e "s/^REVISION_${application}=.*$/REVISION_${application}=${revisions[$application]}/g" .env
    fi
done

echo "Linking files"
for file in "$HOME"/files/*; do
    ln -sf "$file" files/
done

echo "Linking secrets"
for secret in "$HOME"/secrets/*.secret; do
    ln -sf "$secret" secrets/
done

echo "Starting applications"
# creates persistence-oriented volumes
.docker/initialize-volumes.sh
# avoid nginx+fpm shared volumes persisting files from older releases
docker-compose -f docker-compose.yml -f docker-compose.secrets.yml down --remove-orphans --volumes
# (re)start containers
docker-compose -f docker-compose.yml -f docker-compose.secrets.yml up --force-recreate --detach
# waits and executes smoke tests
# HTTP_PORT to be removed after backward compatibility
COMPOSE_PROJECT_NAME=sample-configuration ENVIRONMENT_NAME="${ENVIRONMENT_NAME}" PUBLIC_PORT_HTTP="${PUBLIC_PORT_HTTP}" PUBLIC_PORT_HTTPS="${PUBLIC_PORT_HTTPS}" .travis/smoke-test.sh
# populate the services
COMPOSE_PROJECT_NAME=sample-configuration ENVIRONMENT_NAME="${ENVIRONMENT_NAME}" PUBLIC_PORT_HTTP="${PUBLIC_PORT_HTTP}" PUBLIC_PORT_HTTPS="${PUBLIC_PORT_HTTPS}" POPULATE_CONTENT_STORES="${POPULATE_CONTENT_STORES}" .docker/populate-services.sh
