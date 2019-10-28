#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Wait for cf-operator to start.
wait_for_crd() {
  local timeout="300"
  until bazel run @kubectl//:kubectl -- get crd "${BOSHDEPLOYMENT_CRD}" 2> /dev/null || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

echo "Waiting for the cf-operator pod to become available..."
wait_for_crd || {
  >&2 echo "Timed out waiting for the cf-operator pod"
  exit 1
}
