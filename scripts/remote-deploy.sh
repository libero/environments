#!/bin/bash
# shipped to a remote virtual machine to deploy sample-configuration there
set -ex

cd /tmp
if [ ! -d sample-configuration ]; then
    git clone https://github.com/libero/sample-configuration --recurse-submodules
    cd sample-configuration
else
    cd sample-configuration
    git pull origin master
    git submodule update
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

if [ -n "$REVISION_DUMMY_API" ]; then
    sed -i -e "s/^REVISION_DUMMY_API=.*$/REVISION_DUMMY_API=$REVISION_DUMMY_API/g" .env
fi

# avoid nginx+fpm shared volumes persisting files from older releases
# assume all service are stateless
docker-compose down -v
docker-compose up --force-recreate -d

# compare PUBLIC_PORT in .env, if provided
HTTP_PORT=80 .travis/smoke-test.sh
