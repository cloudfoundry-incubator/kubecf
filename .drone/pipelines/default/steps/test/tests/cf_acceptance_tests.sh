#!/usr/bin/env bash

set -o errexit -o nounset

# Trigger cf-acceptance-tests.
bazel run //testing/acceptance_tests

cf_acceptance_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "acceptance-tests"
}

# Wait for cf-acceptance-tests to start.
wait_for_cf_acceptance_tests_pod() {
  local timeout="300"
  until kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep --quiet "acceptance-tests" || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  pod_name="$(cf_acceptance_tests_pod_name)"
  until [[ "$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output jsonpath='{.status.containerStatuses[?(@.name == "acceptance-tests-acceptance-tests")].state.running}' 2> /dev/null)" != "" ]] || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

echo "Waiting for the cf-acceptance-tests pod to start..."
wait_for_cf_acceptance_tests_pod || {
  >&2 echo "Timed out waiting for the cf-acceptance-tests pod"
  exit 1
}

# Follow the logs. If the tests fail, the logs command will also fail.
pod_name="$(cf_acceptance_tests_pod_name)"
kubectl logs --follow "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --container acceptance-tests-acceptance-tests

# Wait for the container to terminate and then exit the script with the container's exit code.
jsonpath='{.status.containerStatuses[?(@.name == "acceptance-tests-acceptance-tests")].state.terminated.exitCode}'
while true; do
  exit_code="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}")"
  if [[ -n "${exit_code}" ]]; then
    exit "${exit_code}"
  fi
  sleep 1
done
