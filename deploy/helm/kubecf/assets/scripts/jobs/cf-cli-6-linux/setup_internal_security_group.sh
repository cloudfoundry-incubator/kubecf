#!/bin/bash

set -o errexit -o nounset -o xtrace

export PATH="${CF_CLI_PATH}:${PATH}"

until curl --insecure --fail --silent --head "${CF_API}"; do
    sleep 1
done

cf api --skip-ssl-validation "${CF_API}"
cf auth

sec_group_json=$(cat <<EOF
[{
    "protocol": "tcp",
    "description": "Allow traffic to ${POD_NAME}",
    "destination": "${POD_IP}/32",
    "ports": "${PORTS}"
}]
EOF
)

sec_group_name="internal-${POD_NAME}"

if ! cf security-group "${sec_group_name}"; then
    cf create-security-group "${sec_group_name}" <(echo -n "${sec_group_json}")
    cf bind-staging-security-group "${sec_group_name}"
    cf bind-running-security-group "${sec_group_name}"
else
    cf update-security-group "${sec_group_name}" <(echo -n "${sec_group_json}")
fi

tail --pid 1 --follow /dev/null
