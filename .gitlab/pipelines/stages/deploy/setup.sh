#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

wait_for_file() {
  local file_path="$1"
  local timeout="${2:-30}"
  until [[ -f "${file_path}" ]] || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

printf "k3s: %s\n" "$(bazel run @k3s//executable -- --version 2> /dev/null)"
sudo -E "$(command -v bazel)" run @k3s//executable -- server 1> /tmp/k3s.out.log 2> /tmp/k3s.err.log &
k3s_kubeconfig="/etc/rancher/k3s/k3s.yaml"
kubeconfig="${HOME}/.kube/config"
wait_for_file "${k3s_kubeconfig}" || {
  >&2 echo "${k3s_kubeconfig} did not get created"
}
mkdir -p "$(dirname "${kubeconfig}")"
sudo cp "${k3s_kubeconfig}" "${kubeconfig}"
sudo chown "$(id -u)":"$(id -g)" "${kubeconfig}"

bazel run //dev/kube/local_path_provisioner:apply
bazel run @kubectl//:kubectl -- patch storageclass local-path \
  --patch '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true", "storageclass.beta.kubernetes.io/is-default-class":"true"}}}'

bazel run @kubectl//:kubectl -- create namespace "${CF_OPERATOR_NAMESPACE}"
