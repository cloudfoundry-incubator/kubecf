#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

wait_kubecf() {
  timeout 900 bash <<EOF
while true; do
  if '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers --ignore-not-found | grep "router"; then
    exit 0
  fi
  sleep 1
done
EOF
  timeout 900 bash <<EOF
pod_count() {
  '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers --ignore-not-found \
    | wc --lines
}

ready_pod_count() {
  '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers --ignore-not-found \
    | awk '{ printf "%s-%s\n", \$2, \$3 }' | grep --line-regexp '\(.*\)\/\1-Running' \
    | wc --lines
}

print_status() {
  timestamp="\$(date +"%T")"
  printf "%s - %d of %d pods ready.\n" "\${timestamp}" "\${1}" "\${2}"
}

i=0
while true; do
  total="\$(pod_count)"
  ready="\$(ready_pod_count)"
  if [[ "\${total}" > "0" ]] && [[ "\${total}" == "\${ready}" ]]; then
    print_status "\${ready}" "\${total}"
    exit 0
  fi
  if (( i % 60 == 0 )); then
    print_status "\${ready}" "\${total}"
  fi
  sleep 1
  i=\$((i + 1))
done
EOF
}

echo "Waiting for kubecf to be ready..."
wait_kubecf || {
  >&2 echo "Timed out waiting for kubecf to be ready"
  exit 1
}
