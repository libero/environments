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
branch_name="${BRANCH_NAME:-master}"
docker_libero_namespace="liberoadmin"

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
    revision=$(scripts/latest-revision.sh "${docker_libero_namespace}/${application}")
    environment_variable_name="REVISION_$(echo "$application" | tr '[:lower:]' '[:upper:]' | tr - _)"
    environment="${environment} $environment_variable_name=${revision}"
done

environment_variables_file="environments/${environment_name}.env"
if [ ! -e "${environment_variables_file}" ]; then
    echo "Missing configuration file: ${environment_variables_file}"
    exit 2
fi
# shellcheck source=environments/unstable.env
source "${environment_variables_file}"

for environment_variable_name in BROWSER_GTM_ID ENVIRONMENT_NAME PUBLIC_PORT_HTTP PUBLIC_PORT_HTTPS POPULATE_CONTENT_STORES; do
    environment="${environment} ${environment_variable_name}=${!environment_variable_name}"
done

ssh -o StrictHostKeyChecking=no -i "$key" "$ssh_hostname" "$environment" BRANCH_NAME="${branch_name}" /tmp/remote-deploy.sh
