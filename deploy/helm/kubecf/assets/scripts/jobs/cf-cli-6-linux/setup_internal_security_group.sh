#!/bin/bash

# Never use -x or -o xtrace here because of security reasons.
set -o errexit -o nounset -o pipefail

export PATH="${CF_CLI_PATH}:${PATH}"

# Write the CF_API_CA_CERT environment variable to a PEM file and set SSL_CERT_FILE pointing to it.
if [ "${CF_API_CA_CERT:-}" != "" ]; then
    cf_api_ca_cert_pem="${DATA_DIR}/cf_api_ca_cert.pem"
    echo -n "${CF_API_CA_CERT}" > "${cf_api_ca_cert_pem}"
    export SSL_CERT_FILE="${cf_api_ca_cert_pem}"
fi

# Wait for the CF API to be accessible.
echo "Waiting for the API to be accessible..."
while true; do
    set +o errexit
    output=$(curl --fail --head "${CF_API}/v2/info" 2>&1)
    code=$?
    set -o errexit
    if [ "${code}" == "60" ]; then
        >&2 echo "${output}"
        exit 1
    fi
    if [ "${code}" == "0" ]; then break; fi
    sleep 1
done

# Setup the cf-cli.
cf api "${CF_API}"
cf auth --client-credentials

# Define the security group JSON.
sec_group_json=$(cat <<EOF
[{
    "protocol": "tcp",
    "description": "Allow traffic to ${POD_NAME}",
    "destination": "${POD_IP}/32",
    "ports": "${PORTS}"
}]
EOF
)

# Create the security group if it doens't exist, otherwise update it.
sec_group_name="internal-${POD_NAME}"
if ! cf security-group "${sec_group_name}"; then
    cf create-security-group "${sec_group_name}" <(echo -n "${sec_group_json}")
    cf bind-staging-security-group "${sec_group_name}"
    cf bind-running-security-group "${sec_group_name}"
else
    cf update-security-group "${sec_group_name}" <(echo -n "${sec_group_json}")
fi

# Setup a cleanup for the security group on exit.
cleanup() {
    cf unbind-staging-security-group "${sec_group_name}"
    cf unbind-running-security-group "${sec_group_name}"
    cf delete-security-group -f "${sec_group_name}"
}
trap cleanup EXIT

# Wait until pid 1 is terminated. I.e. wait for the pod to receive SIGINT.
tail --pid 1 --follow /dev/null
