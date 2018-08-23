#!/bin/bash
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

if [ -n "$revision_browser" ]; then
    sed -i -e "s/^REVISION_BROWSER=.*$/REVISION_BROWSER=$revision_browser" .env
fi

docker-compose up --force-recreate -d
