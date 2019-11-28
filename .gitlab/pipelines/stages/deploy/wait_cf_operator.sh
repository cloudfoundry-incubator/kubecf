#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

deployments=$("${KUBECTL}" get --namespace "${CF_OPERATOR_NAMESPACE}" deployments --output name)

echo "Waiting for the cf-operator deployments to be available..."
for deployment in $deployments; do
  "${KUBECTL}" wait "${deployment}" \
    --for condition=Available \
    --timeout=300s \
    --namespace "${CF_OPERATOR_NAMESPACE}"
done
