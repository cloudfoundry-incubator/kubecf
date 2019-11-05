#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"

wait_for_file() {
  local file_path="$1"
  local timeout="${2:-30}"
  for (( ; timeout > 0 ; timeout -- )); do
    if [[ -f "${file_path}" ]]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

"${K3S}" --version 2> /dev/null

sudo "${K3S}" server --log /dev/null &

k3s_kubeconfig="/etc/rancher/k3s/k3s.yaml"
kubeconfig="${HOME}/.kube/config"
if ! wait_for_file "${k3s_kubeconfig}"; then
  >&2 echo "${k3s_kubeconfig} did not get created"
  exit 1
fi
mkdir -p "$(dirname "${kubeconfig}")"
(sudo cat "${k3s_kubeconfig}") > "${kubeconfig}"

bazel run //dev/kube/local_path_provisioner:apply
"${KUBECTL}" patch storageclass local-path \
  --patch '{
  "metadata": {
    "annotations": {
      "storageclass.kubernetes.io/is-default-class": "true",
      "storageclass.beta.kubernetes.io/is-default-class": "true"
    }
  }
}'

"${KUBECTL}" create namespace "${CF_OPERATOR_NAMESPACE}"
