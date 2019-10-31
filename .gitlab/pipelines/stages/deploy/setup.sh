#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

sudo curl -o /usr/local/bin/k3s -L https://github.com/rancher/k3s/releases/download/v0.9.1/k3s && sudo chmod +x /usr/local/bin/k3s
sudo /usr/local/bin/k3s server 1> /dev/null 2> /dev/null &
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$(id -u)":"$(id -g)" ~/.kube/config

bazel run @kubectl//:kubectl -- create namespace "${CF_OPERATOR_NAMESPACE}"
