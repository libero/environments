#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
    echo "USAGE $0 ENVIRONMENT_NAME"
    exit 1
fi

environment_name="$1"
hostname="${environment_name}.libero.pub"
ssh $hostname deploy-latest browser=$(scripts/latest-revision.sh git@github.com:libero/browser)
