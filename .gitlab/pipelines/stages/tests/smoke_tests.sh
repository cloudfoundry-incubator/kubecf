#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Trigger smoke-tests.
bazel run //testing/smoke_tests

# Wait for smoke-tests to start.
smoke_tests_pod_name() {
  bazel run @kubectl//:kubectl -- get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "smoke-tests"
}

wait_for_smoke_tests_pod() {
  local timeout="300"
  until bazel run @kubectl//:kubectl -- get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep --quiet "smoke-tests" || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  pod_name="$(smoke_tests_pod_name)"
  until [[ "$(bazel run @kubectl//:kubectl -- get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output jsonpath='{.status.containerStatuses[?(@.name == "smoke-tests-smoke-tests")].state.running}' 2> /dev/null)" != "" ]] || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

echo "Waiting for the smoke-tests pod to start..."
wait_for_smoke_tests_pod || {
  >&2 echo "Timed out waiting for the smoke-tests pod"
  exit 1
}

# Follow the logs. If the tests fail, the logs command will also fail.
pod_name="$(smoke_tests_pod_name)"
bazel run @kubectl//:kubectl -- logs --follow "${pod_name}" --namespace "${KUBECF_NAMESPACE}" smoke-tests-smoke-tests
