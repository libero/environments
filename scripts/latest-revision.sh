#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
    echo "USAGE $0 GIT_REMOTE_REPOSITORY"
    exit 1
fi

remote="$1"
folder=$(basename "$remote")

rm -rf "$folder"
git clone --depth=1 "$remote" "$folder"
cd "$folder"
git rev-parse master
