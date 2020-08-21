#!/bin/bash

# Never use -x or -o xtrace here because of security reasons.
set -o errexit -o nounset -o pipefail

# wait_for_endpoint waits for an endpoint to be ready. It fails if the error is related to the
# certificate.
function wait_for_endpoint() {
    local ca_cert="$1"
    local endpoint="$2"
    while true; do
        # Unset errexit to be able to process the error code from curl.
        set +o errexit
        output=$(curl --cacert "${ca_cert}" --fail --head --silent --show-error "${endpoint}" 2>&1)
        code=$?
        set -o errexit
        case "${code}" in
        60)
            >&2 echo "${output}"
            return 1 ;;
        0)
            return 0 ;;
        *)
            sleep 1 ;;
        esac
    done
}

# get_access_token returns a token to be used on the CF API calls.
function get_access_token() {
    local url="$1"
    local cacert="$2"
    local client_id="$3"
    local client_secret="$4"
    curl \
        --silent --show-error --fail \
        --cacert "${cacert}" \
        --request POST \
        --data "scope=cloud_controller.admin" \
        --data "grant_type=client_credentials" \
        --data "client_id=${client_id}" \
        --data "client_secret=${client_secret}" \
        "${url}" \
        | jq -r '.access_token'
}

# check_security_group checks if the security group already exists.
function check_security_group() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_name="$4"
    local total_results
    total_results=$(
        curl \
            --silent --show-error --fail \
            --cacert "${cacert}" \
            --header "Authorization: Bearer ${access_token}" \
            "${cf_api}/v2/security_groups?q=name:${sec_group_name}" \
            | jq -r '.total_results'
    )
    if [[ "${total_results}" == "0" ]]; then return 1; fi
}

# get_sec_group_id returns the security group ID.
function get_sec_group_id() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_name="$4"
    curl \
        --silent --show-error --fail \
        --cacert "${cacert}" \
        --header "Authorization: Bearer ${access_token}" \
        "${cf_api}/v2/security_groups?q=name:${sec_group_name}" \
        | jq -r '.resources[0].metadata.guid'
}

# create_security_group creates the new security group.
function create_security_group() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_json="$4"
    curl \
        --silent --show-error --fail \
        --cacert "${cacert}" \
        --header "Authorization: Bearer ${access_token}" \
        --header "Content-Type: application/json" \
        --request POST \
        --data "${sec_group_json}" \
         "${cf_api}/v2/security_groups" \
        1> /dev/null
}

# update_security_group updates the security group with the up-to-date JSON definition.
function update_security_group() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_id="$4"
    local sec_group_json="$5"
    curl \
        --silent --show-error --fail \
        --cacert "${cacert}" \
        --header "Authorization: Bearer ${access_token}" \
        --header "Content-Type: application/json" \
        --request PUT \
        --data "${sec_group_json}" \
        "${cf_api}/v2/security_groups/${sec_group_id}" \
        1> /dev/null
}

# delete_security_group deletes the security group. It assumes the staging and running configs are
# unbound.
function delete_security_group() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_id="$4"
    curl \
        --silent --show-error --fail \
        --cacert "${cacert}" \
        --header "Authorization: Bearer ${access_token}" \
        --request DELETE \
        "${cf_api}/v2/security_groups/${sec_group_id}" \
        1> /dev/null
}

# bind_security_group binds the security group to the staging and running configs.
function bind_security_group() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_id="$4"
    local configs=(
        "staging_security_groups"
        "running_security_groups"
    )
    for config in "${configs[@]}"; do
        curl \
            --silent --show-error --fail \
            --cacert "${cacert}" \
            --header "Authorization: Bearer ${access_token}" \
            --request PUT \
            "${cf_api}/v2/config/${config}/${sec_group_id}" \
            1> /dev/null
    done
}

# unbind_security_group unbinds the security group from the staging and running configs.
function unbind_security_group() {
    local cf_api="$1"
    local cacert="$2"
    local access_token="$3"
    local sec_group_id="$4"
    local configs=(
        "staging_security_groups"
        "running_security_groups"
    )
    for config in "${configs[@]}"; do
        curl \
            --silent --show-error --fail \
            --cacert "${cacert}" \
            --header "Authorization: Bearer ${access_token}" \
            --request DELETE \
            "${cf_api}/v2/config/${config}/${sec_group_id}" \
            1> /dev/null
    done
}

# Write the CF_API_CA_CERT and UAA_CA_CERT environment variable contents to PEM files.
if [ "${CF_API_CA_CERT:-}" != "" ]; then
    cf_api_ca_cert_pem="${DATA_DIR}/cf_api_ca_cert.pem"
    echo -n "${CF_API_CA_CERT}" > "${cf_api_ca_cert_pem}"
    uaa_ca_cert_pem="${DATA_DIR}/uaa_ca_cert.pem"
    echo -n "${UAA_CA_CERT}" > "${uaa_ca_cert_pem}"
fi

# Wait for the CF API to be accessible.
echo "Waiting for the API to be accessible..."
# shellcheck disable=SC2153
wait_for_endpoint "${cf_api_ca_cert_pem}" "${CF_API}/v2/info"

# Wait for UAA to be accessible.
echo "Waiting for UAA to be accessible..."
wait_for_endpoint "${uaa_ca_cert_pem}" "${UAA_URL}/info"

# Construct the security group JSON definition.
sec_group_name="internal-${POD_NAME}"
sec_group_json=$(cat <<EOF
{
    "name": "${sec_group_name}",
    "rules": [{
        "protocol": "tcp",
        "description": "Allow traffic to ${POD_NAME}",
        "destination": "${POD_IP}/32",
        "ports": "${PORTS}"
    }]
}
EOF
)

# Create the security group if it doesn't exist, otherwise, update it.
echo "Getting access token..."
access_token=$(
    get_access_token \
        "${UAA_URL}/oauth/token" \
        "${uaa_ca_cert_pem}" \
        "${CF_USERNAME}" \
        "${CF_PASSWORD}"
)
echo "Checking if security group ${sec_group_name} already exists..."
if ! check_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_name}"; then
    echo "Creating security group ${sec_group_name}..."
    create_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_json}"
    echo "Binding security group ${sec_group_name}..."
    sec_group_id=$(
        get_sec_group_id \
            "${CF_API}" \
            "${cf_api_ca_cert_pem}" \
            "${access_token}" \
            "${sec_group_name}"
    )
    bind_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_id}"
else
    echo "Updating security group ${sec_group_name}..."
    sec_group_id=$(
        get_sec_group_id \
            "${CF_API}" \
            "${cf_api_ca_cert_pem}" \
            "${access_token}" \
            "${sec_group_name}"
    )
    update_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_id}" \
        "${sec_group_json}"
    echo "Binding security group ${sec_group_name}..."
    bind_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_id}"
fi

# Setup a cleanup for the security group on exit.
cleanup() {
    echo "Getting access token..."
    access_token=$(
        get_access_token \
            "${UAA_URL}/oauth/token" \
            "${uaa_ca_cert_pem}" \
            "${CF_USERNAME}" \
            "${CF_PASSWORD}"
    )
    echo "Unbinding security group ${sec_group_name}..."
    sec_group_id=$(
        get_sec_group_id \
            "${CF_API}" \
            "${cf_api_ca_cert_pem}" \
            "${access_token}" \
            "${sec_group_name}"
    )
    unbind_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_id}"
    echo "Deleting security group ${sec_group_name}..."
    delete_security_group \
        "${CF_API}" \
        "${cf_api_ca_cert_pem}" \
        "${access_token}" \
        "${sec_group_id}"
}
trap cleanup EXIT

# Wait until pid 1 is terminated. I.e. wait for the pod to receive SIGINT.
echo "Done! Waiting for cleanup signal..."
tail --pid 1 --follow /dev/null
