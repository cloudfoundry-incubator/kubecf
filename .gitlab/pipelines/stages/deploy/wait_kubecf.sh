#!/usr/bin/env bash

# This script waits for kubecf initial deployment. It does not currently cover upgrades or config
# changes.

set -o errexit -o nounset

on_exit() {
  echo "Failed to wait for kubecf pods"
}
trap on_exit EXIT

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/binaries.sh"

echo "Waiting for the kubecf pods to be ready..."

secret_name="${KUBECF_INSTALL_NAME}.with-ops"

until "${KUBECTL}" get secret "${secret_name}" \
  --namespace "${KUBECF_NAMESPACE}" \
  --output jsonpath='{ .data.manifest\.yaml }' \
  1> /dev/null 2> /dev/null; do
  sleep 1
done

instance_groups=()
while IFS='' read -r line; do instance_groups+=("${line}"); done < <(
  "${KUBECTL}" get secret "${secret_name}" \
    --namespace "${KUBECF_NAMESPACE}" \
    --output jsonpath='{ .data.manifest\.yaml }' \
    | base64 --decode \
    | "${YQ}" read --tojson - \
    | "${JQ}" -r '.instance_groups[] | select(.lifecycle != "errand") | select (.lifecycle != "auto-errand") | .name'
)

for instance_group in "${instance_groups[@]}"; do
  until [[ $("${KUBECTL}" get pod \
    --selector "quarks.cloudfoundry.org/instance-group-name=${instance_group}" \
    --namespace "${KUBECF_NAMESPACE}" \
    --output json \
    | "${JQ}" -r '.items | length') -gt 0 ]]; do
      sleep 1
  done

  "${KUBECTL}" wait pods \
    --selector "quarks.cloudfoundry.org/instance-group-name=${instance_group}" \
    --for condition=Ready \
    --timeout=1800s \
    --namespace "${KUBECF_NAMESPACE}"
done

# Wait for non-quarks jobs
"${KUBECTL}" wait jobs \
  --selector "!quarks.cloudfoundry.org/qjob-name" \
  --for condition=Complete \
  --timeout=1800s \
  --namespace "${KUBECF_NAMESPACE}"

trap "" EXIT
echo "Finished waiting for the kubecf pods to be ready."
