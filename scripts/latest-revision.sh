#!/bin/bash
# finds out the commit sha of the latest revision of a repository,
# with minimal cloning
set -e

if [ "$#" -ne 1 ]; then
    echo "USAGE $0 GIT_REMOTE_REPOSITORY"
    exit 1
fi

remote="$1"
folder=$(basename "$remote")

cd remotes
rm -rf "./$folder"
git clone --depth=1 "$remote" "$folder"
cd "$folder"
git rev-parse master
