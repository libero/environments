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
# avoid nginx+fpm shared volumes persisting files from older releases
# assume all service are stateless
docker-compose down -v
docker-compose up --force-recreate -d
COMPOSE_PROJECT_NAME=sample-configuration HTTP_PORT=80 .travis/smoke-test.sh

# Populate the search service
curl --verbose --request POST http://localhost:8081/search/populate
