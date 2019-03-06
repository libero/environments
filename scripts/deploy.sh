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

# list of applications
declare -a applications=(browser dummy-api pattern-library)
# environment variables string
declare environment
for application in "${applications[@]}"
do
    revision=$(scripts/latest-revision.sh "https://github.com/libero/${application}.git")
    environment_variable_name="REVISION_$(echo $application | tr a-z A-Z | tr - _)"
    environment="${environment} $environment_variable_name=${revision}"
done

ssh -o StrictHostKeyChecking=no -i "$key" "$ssh_hostname" PUBLIC_PORT=${public_port} $environment /tmp/remote-deploy.sh
