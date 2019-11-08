#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

wait_kubecf() {
  timeout 1800 bash -c "
    pod_count() {
      '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers \
        | wc -l
    }
    ready_pod_count() {
      '${KUBECTL}' get pods --namespace ${KUBECF_NAMESPACE} --no-headers \
        | awk '{ printf \"%s-%s\n\", \$2, \$3 }' | grep -x '\(.*\)\/\1-Running' \
        | wc -l
    }
    while true; do
      if [[ \"\$(pod_count)\" != \"0\" ]] && [[ \"\$(pod_count)\" == \"\$(ready_pod_count)\" ]]; then
        exit 0
      fi
      sleep 1
    done
  "
}

echo "Waiting for kubecf to be ready..."
wait_kubecf || {
  >&2 echo "Timed out waiting for kubecf to be ready"
  exit 1
}
