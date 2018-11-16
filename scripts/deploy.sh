#!/bin/bash
# deploys to a remote VM
set -ex

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 SSH_HOSTNAME SSH_KEY_FILE"
    echo "Example: $0 user@something.libero.pub ~/.ssh/id_rsa"
    exit 1
fi

ssh_hostname="$1"
key="$2"
public_port=80

scp -o StrictHostKeyChecking=no -i "$key" scripts/remote-deploy.sh "$ssh_hostname":/tmp/remote-deploy.sh
revision_browser=$(scripts/latest-revision.sh https://github.com/libero/browser.git)
revision_dummy_api=$(scripts/latest-revision.sh https://github.com/libero/dummy-api.git)
ssh -o StrictHostKeyChecking=no -i "$key" "$ssh_hostname" PUBLIC_PORT=${public_port} REVISION_BROWSER="$revision_browser" REVISION_DUMMY_API="$revision_dummy_api" /tmp/remote-deploy.sh
