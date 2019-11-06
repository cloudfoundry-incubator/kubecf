#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

# Wait for cf-operator to start.
wait_for_crd() {
  local timeout
  for (( timeout = 300; timeout > 0; timeout -- )); do
    if "${KUBECTL}" get crd "${BOSHDEPLOYMENT_CRD}" 2> /dev/null; then
      return 0
    fi
    sleep 1
  done
  return 1
}

echo "Waiting for the cf-operator pod to become available..."
wait_for_crd || {
  >&2 echo "Timed out waiting for the cf-operator pod"
  exit 1
}
