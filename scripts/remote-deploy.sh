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

if [ -n "$PUBLIC_PORT" ]; then
    sed -i -e "s/^PUBLIC_PORT=.*$/PUBLIC_PORT=$PUBLIC_PORT/g" .env
fi

echo "Setting revisions of applications"
declare -A revisions=()
revisions[CONTENT_STORE]="$REVISION_CONTENT_STORE"
revisions[BROWSER]="$REVISION_BROWSER"
revisions[DUMMY_API]="$REVISION_DUMMY_API"
revisions[PATTERN_LIBRARY]="$REVISION_PATTERN_LIBRARY"
revisions[SEARCH]="$REVISION_SEARCH"
for application in "${!revisions[@]}"
do
    if [ -n "${revisions[$application]}" ]; then
        sed -i -e "s/^REVISION_${application}=.*$/REVISION_${application}=${revisions[$application]}/g" .env
    fi
done

echo "Linking secrets"
for secret in "$HOME"/secrets/*.secret; do
    ln -sf "$secret" secrets/
done

echo "Starting applications"
# creates persistence-oriented volumes
.docker/initialize-volumes.sh
# avoid nginx+fpm shared volumes persisting files from older releases
docker-compose -f docker-compose.yml -f docker-compose.secrets.yml down --remove-orphans -v
# (re)start containers
docker-compose -f docker-compose.yml -f docker-compose.secrets.yml up --force-recreate -d
# waits and executes smoke tests
COMPOSE_PROJECT_NAME=sample-configuration HTTP_PORT=80 .travis/smoke-test.sh
# populate the services
.docker/populate-services.sh
