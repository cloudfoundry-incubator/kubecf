#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

get_endpoint() {
  bazel run @kubectl//:kubectl -- get endpoints kubecf-router-public \
    --namespace "${KUBECF_NAMESPACE}" \
    --output jsonpath='{.subsets[0].addresses[0].ip}' 2> /dev/null
}

# Wait for kubecf to start.
wait_for_router() {
  local timeout
  for (( timeout = 1800; timeout > 0; timeout -- )); do
    if [[ "$(get_endpoint)" != "" ]]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

echo "Waiting for the router pod to become available..."
wait_for_router || {
  >&2 echo "Timed out waiting for the router pod"
  exit 1
}
