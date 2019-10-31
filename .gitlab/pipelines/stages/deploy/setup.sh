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

sudo curl -o /usr/local/bin/k3s -L https://github.com/rancher/k3s/releases/download/v0.9.1/k3s && sudo chmod +x /usr/local/bin/k3s
sudo /usr/local/bin/k3s server 1> /tmp/k3s.out.log 2> /tmp/k3s.err.log &
mkdir -p ~/.kube
wait_for_file /etc/rancher/k3s/k3s.yaml || {
  >&2 echo "/etc/rancher/k3s/k3s.yaml did not get created"
}
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$(id -u)":"$(id -g)" ~/.kube/config

bazel run @kubectl//:kubectl -- create namespace "${CF_OPERATOR_NAMESPACE}"
