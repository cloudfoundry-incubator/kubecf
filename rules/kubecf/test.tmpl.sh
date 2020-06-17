#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

alias kubectl="[[kubectl]]"
qjob_name="[[qjob_name]]"
namespace="[[namespace]]"

# Trigger the test.
kubectl patch qjob "${qjob_name}" \
  --namespace "${namespace}" \
  --type merge \
  --patch '{ "spec": { "trigger": { "strategy": "now" } } }'

pod_name() {
  kubectl get pods \
    --namespace "${namespace}" \
    --selector "quarks.cloudfoundry.org/qjob-name=${qjob_name}" \
    --output name \
    | sed 's|^pod\/||' \
    | grep "${qjob_name}"
}

container_name() {
  kubectl get pods \
    --namespace "${namespace}" \
    --selector "quarks.cloudfoundry.org/qjob-name=${qjob_name}" \
    --output jsonpath='{ .items[].spec.containers[0].name }'
}

is_container_running() {
  local pod_name="$1"
  local container_name="$2"
  if [[ "$(kubectl get pods "${pod_name}" \
            --namespace "${namespace}" \
            --output jsonpath="{.status.containerStatuses[?(@.name == \"${container_name}\")].state.running}")" != "" ]]; then
    return 0
  fi
  return 1
}

# Wait for test pod to start.
wait_for_test_running() {
  local timeout="300"
  until pod_name 1> /dev/null || [[ "$timeout" == "0" ]]; do
    sleep 1
    timeout=$((timeout - 1))
  done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  pod_name="$(pod_name)"
  container_name="$(container_name)"
  until is_container_running "${pod_name}" "${container_name}" || [[ "$timeout" == "0" ]]; do
    sleep 1
    timeout=$((timeout - 1))
  done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

echo "Waiting for the ${qjob_name} pod to start..."
wait_for_test_running || {
  >&2 echo "Timed out waiting for the ${qjob_name} pod"
  exit 1
}

# Tail the test logs.
pod_name="$(pod_name)"
container_name="$(container_name)"
kubectl logs "${pod_name}" \
  --follow \
  --namespace "${namespace}" \
  --container "${container_name}"

# Wait for the container to terminate and then exit the script with the container's exit code.
jsonpath="{.status.containerStatuses[?(@.name == \"${container_name}\")].state.terminated.exitCode}"
while true; do
  exit_code="$(kubectl get pod "${pod_name}" --namespace "${namespace}" --output "jsonpath=${jsonpath}")"
  if [[ -n "${exit_code}" ]]; then
    exit "${exit_code}"
  fi
  sleep 1
done
