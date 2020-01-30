#!/usr/bin/env bash

set -o errexit -o nounset

KUBECTL="$(bazel run //:kubectl_binary_location 2> /dev/null)"
export KUBECTL
K3S="$(bazel run //:k3s_binary_location 2> /dev/null)"
export K3S
JQ="$(bazel run //:jq_binary_location 2> /dev/null)"
export JQ
YQ="$(bazel run //:yq_binary_location 2> /dev/null)"
export YQ
