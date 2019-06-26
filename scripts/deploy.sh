#!/bin/bash
# deploys to a remote VM
set -ex

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 ENVIRONMENT_NAME SSH_HOSTNAME SSH_KEY_FILE"
    echo "Example: $0 production user@something.libero.pub ~/.ssh/id_rsa"
    exit 1
fi

environment_name="$1"
ssh_hostname="$2"
key="$3"
public_port_http=80
public_port_https=443

scp -o StrictHostKeyChecking=no -i "$key" scripts/remote-deploy.sh "$ssh_hostname":/tmp/remote-deploy.sh
ssh -o StrictHostKeyChecking=no -i "$key" "$ssh_hostname" mkdir -p files/
scp -o StrictHostKeyChecking=no -i "$key" -r files/"$environment_name"/* "$ssh_hostname":files/
ssh -o StrictHostKeyChecking=no -i "$key" "$ssh_hostname" mkdir -p secrets/
scp -o StrictHostKeyChecking=no -i "$key" -r secrets/"$environment_name"/* "$ssh_hostname":secrets/

# list of applications
declare -a applications=(browser content-store dummy-api jats-ingester pattern-library search)
# environment variables string
declare environment
for application in "${applications[@]}"
do
    revision=$(scripts/latest-revision.sh "https://github.com/libero/${application}.git")
    environment_variable_name="REVISION_$(echo "$application" | tr '[:lower:]' '[:upper:]' | tr - _)"
    environment="${environment} $environment_variable_name=${revision}"
done

ssh -o StrictHostKeyChecking=no -i "$key" "$ssh_hostname" PUBLIC_PORT_HTTP="${public_port_http}" PUBLIC_PORT_HTTPS="${public_port_https}" "$environment" /tmp/remote-deploy.sh
