#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

wait_kubecf() {
  timeout 1800 bash <<EOF
pod_count() {
  '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers --ignore-not-found \
    | wc --lines
}

ready_pod_count() {
  '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers --ignore-not-found \
    | awk '{ printf "%s-%s\n", \$2, \$3 }' | grep --line-regexp '\(.*\)\/\1-Running' \
    | wc --lines
}

i=0
while true; do
  total="\$(pod_count)"
  ready="\$(ready_pod_count)"
  if [[ "\${total}" > "0" ]] && [[ "\${total}" == "\${ready}" ]]; then
    printf "\r%d of %d pods ready." "\${ready}" "\${total}"
    exit 0
  fi
  if (( i % 60 == 0 )); then
    printf "\r%d of %d pods ready." "\${ready}" "\${total}"
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
