#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Wait for kubecf to start.
wait_for_router() {
  local timeout="1800"
  until [[ "$(bazel run @kubectl//:kubectl -- get endpoints --namespace "${KUBECF_NAMESPACE}" kubecf-router-public --output jsonpath='{.subsets[0].addresses[0].ip}' 2> /dev/null)" != "" ]] || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

echo "Waiting for the router pod to become available..."
wait_for_router || {
  >&2 echo "Timed out waiting for the router pod"
  exit 1
}
