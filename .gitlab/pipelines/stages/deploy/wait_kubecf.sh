#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

echo "Waiting for the kubecf pods to be ready..."

secret_name="${KUBECF_INSTALL_NAME}.with-ops"

until "${KUBECTL}" get secret "${secret_name}" --namespace "${KUBECF_NAMESPACE}" 1> /dev/null 2> /dev/null; do
  sleep 1
done

instance_groups=$(
  "${KUBECTL}" get secret "${secret_name}" \
    --namespace "${KUBECF_NAMESPACE}" \
    -o jsonpath='{ .data.manifest\.yaml }' \
    | base64 --decode \
    | "${YAML2JSON}" \
    | "${JQ}" -r '.instance_groups[] | select(.lifecycle != "errand") | select (.lifecycle != "auto-errand") | .name'
)

for instance_group in $instance_groups; do
  until "${KUBECTL}" get pod --selector "quarks.cloudfoundry.org/instance-group-name=${instance_group}" 1> /dev/null 2> /dev/null; do
    sleep 1
  done

  "${KUBECTL}" wait pods \
    --selector "quarks.cloudfoundry.org/instance-group-name=${instance_group}" \
    --for condition=Ready \
    --timeout=1800s \
    --namespace "${KUBECF_NAMESPACE}"
done
