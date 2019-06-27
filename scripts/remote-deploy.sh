#!/bin/bash
# shipped to a remote virtual machine to deploy sample-configuration there
set -ex

cd "$HOME"
if [ ! -d sample-configuration ]; then
    git clone https://github.com/libero/sample-configuration --recurse-submodules
    cd sample-configuration
else
    cd sample-configuration
    git pull origin master
    git submodule update --init
fi

if [ ! -f .env ]; then
    cp .env.dist .env
fi

if [ -n "$ENVIRONMENT_NAME" ]; then
    sed -i -e "s/^ENVIRONMENT_NAME=.*$/ENVIRONMENT_NAME=$ENVIRONMENT_NAME/g" .env
fi

if [ -n "$PUBLIC_PORT_HTTP" ]; then
    sed -i -e "s/^PUBLIC_PORT_HTTP=.*$/PUBLIC_PORT_HTTP=$PUBLIC_PORT_HTTP/g" .env
fi

if [ -n "$PUBLIC_PORT_HTTPS" ]; then
    sed -i -e "s/^PUBLIC_PORT_HTTPS=.*$/PUBLIC_PORT_HTTPS=$PUBLIC_PORT_HTTPS/g" .env
fi

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
COMPOSE_PROJECT_NAME=sample-configuration PUBLIC_PORT_HTTP="${PUBLIC_PORT_HTTP}" PUBLIC_PORT_HTTPS="${PUBLIC_PORT_HTTPS}" .travis/smoke-test.sh
# populate the services
COMPOSE_PROJECT_NAME=sample-configuration PUBLIC_PORT_HTTP="${PUBLIC_PORT_HTTP}" PUBLIC_PORT_HTTPS="${PUBLIC_PORT_HTTPS}" .docker/populate-services.sh
