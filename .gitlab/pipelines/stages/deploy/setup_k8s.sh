#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

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

printf "k3s: %s\n" "$(bazel run @k3s//executable -- --version 2> /dev/null)"
sudo -E "$(command -v bazel)" run @k3s//executable -- server --log /dev/null &
k3s_kubeconfig="/etc/rancher/k3s/k3s.yaml"
kubeconfig="${HOME}/.kube/config"
if ! wait_for_file "${k3s_kubeconfig}"; then
  >&2 echo "${k3s_kubeconfig} did not get created"
fi
mkdir -p "$(dirname "${kubeconfig}")"
(sudo cat "${k3s_kubeconfig}") > "${kubeconfig}"

bazel run //dev/kube/local_path_provisioner:apply
bazel run @kubectl//:kubectl -- patch storageclass local-path \
  --patch '{
  "metadata": {
    "annotations": {
      "storageclass.kubernetes.io/is-default-class": "true",
      "storageclass.beta.kubernetes.io/is-default-class": "true"
    }
  }
}'

bazel run @kubectl//:kubectl -- create namespace "${CF_OPERATOR_NAMESPACE}"
