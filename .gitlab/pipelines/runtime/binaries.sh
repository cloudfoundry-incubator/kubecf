#!/usr/bin/env bash

set -o errexit -o nounset

KUBECTL="$(bazel run //rules/external_binary:kubectl 2> /dev/null)"
export KUBECTL
K3S="$(bazel run //rules/external_binary:k3s 2> /dev/null)"
export K3S
JQ="$(bazel run //rules/external_binary:jq 2> /dev/null)"
export JQ
YQ="$(bazel run //rules/external_binary:yq 2> /dev/null)"
export YQ
