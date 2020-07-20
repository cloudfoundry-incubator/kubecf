#!/usr/bin/env bash

# This script waits untils the KubeCF deployment is ready

source scripts/include/setup.sh

require_tools kubectl retry

get_resource() {
    kubectl get --output=name --namespace=kubecf "${@}"
}

check_resource_count() {
    local resource="${1}"
    test -n "$(get_resource "${resource}")"
}

green "Waiting for the BOSHDeployment to exist"
RETRIES=30 DELAY=5 retry get_resource BOSHDeployment/kubecf

green "Waiting for the quarks jobs to be done"
check_qjob_ready() {
    local qjob="QuarksJob/${1}"
    local output='--output=jsonpath={.status.completed}'
    test true == "$(get_resource "${qjob}" "${output}")"
}
RETRIES=180 DELAY=10 retry check_qjob_ready dm
RETRIES=180 DELAY=10 retry check_qjob_ready ig

green "Waiting for things to exist"
resources=(
    Service/uaa Service/api Service/router-public
    StatefulSet/uaa StatefulSet/api StatefulSet/router
)
for resource in "${resources[@]}" ; do
    RETRIES=30 DELAY=5 retry get_resource "${resource}"
done

RETRIES=60 DELAY=5 retry check_resource_count pods

green "Waiting for all deployments to be available"
wait_for_condition() {
    local condition="${1}"
    shift
    local resource
    for resource in "${@}" ; do
        retry kubectl wait --for="${condition}" --namespace=kubecf --timeout=600s "${resource}"
    done
}

RETRIES=60 DELAY=5 retry check_resource_count deployments
mapfile -t deployments < <(get_resource deployments)
RETRIES=60 DELAY=5 wait_for_condition condition=Available "${deployments[@]}"

green "Waiting for all endpoints to be available"
wait_for_endpoint() {
    local endpoint="${1}"
    local output='--output=jsonpath={.subsets.*.addresses.*.ip}'
    test -n "$(get_resource "${endpoint}" "${output}")"
}

RETRIES=60 DELAY=5 retry check_resource_count endpoints
mapfile -t endpoints < <(get_resource endpoints)
for endpoint in "${endpoints[@]}" ; do
    RETRIES=180 DELAY=10 retry wait_for_endpoint "${endpoint}"
done
