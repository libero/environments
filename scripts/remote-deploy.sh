#!/bin/bash
# shipped to a remote virtual machine to deploy sample-configuration there
set -e

cd /tmp
if [ ! -d sample-configuration ]; then
    git clone https://github.com/libero/sample-configuration
    cd sample-configuration
else
    cd sample-configuration
    git pull origin master
fi

if [ ! -f .env ]; then
    cp .env.dist .env
fi

if [ -n "$PUBLIC_PORT" ]; then
    sed -i -e "s/^PUBLIC_PORT=.*$/PUBLIC_PORT=$PUBLIC_PORT/g" .env
fi

if [ -n "$REVISION_BROWSER" ]; then
    sed -i -e "s/^REVISION_BROWSER=.*$/REVISION_BROWSER=$REVISION_BROWSER/g" .env
fi

docker-compose up --force-recreate -d
