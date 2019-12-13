#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"

deployments=$(kubectl get --namespace "${CF_OPERATOR_NAMESPACE}" deployments --output name)

echo "Waiting for the cf-operator deployments to be available..."
for deployment in $deployments; do
  kubectl wait "${deployment}" \
    --for condition=Available \
    --timeout=300s \
    --namespace "${CF_OPERATOR_NAMESPACE}"
done
