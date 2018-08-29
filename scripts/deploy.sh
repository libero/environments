#!/bin/bash
# deploys to a remote VM
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 SSH_HOSTNAME SSH_KEY_FILE"
    echo "Example: $0 user@something.libero.pub ~/.ssh/id_rsa"
    exit 1
fi

ssh_hostname="$1"
key="$2"
public_port=80

scp -i "$key" scripts/remote-deploy.sh "$ssh_hostname":/tmp/remote-deploy.sh
revision_browser=$(scripts/latest-revision.sh git@github.com:libero/browser)
ssh -i "$key" "$ssh_hostname" PUBLIC_PORT=${public_port} REVISION_BROWSER="$revision_browser" /tmp/remote-deploy.sh
