#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Wait for kubecf to start.
wait_for_router() {
  local timeout="1800"
  until curl -k --fail --head --silent "https://api.${SYSTEM_DOMAIN}/v2/info" || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

echo "Waiting for the router pod to become available..."
wait_for_router || {
  >&2 echo "Timed out waiting for the router pod"
  exit 1
}
