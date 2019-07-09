#!/bin/bash
# finds out the commit sha originating a latest Docker image,
# by pulling it and reading labels
set -e

if [ "$#" -ne 1 ]; then
    echo "USAGE $0 DOCKER_IMAGE [TAG]"
    echo "Example: $0 liberoadmin/browser latest"
    exit 1
fi

image_name="$1"
tag="${2:-latest}"

docker pull "${image_name}:${tag}" 1>&2
docker inspect liberoadmin/search:latest | jq -r '.[0].Config.Labels."org.opencontainers.image.revision"'
