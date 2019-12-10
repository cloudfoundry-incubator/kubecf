#!/usr/bin/env bash

set -o errexit -o nounset

KUBECTL="$(bazel run //rules/external_binary:kubectl_binary_location 2> /dev/null)"
export KUBECTL
K3S="$(bazel run //rules/external_binary:k3s_binary_location 2> /dev/null)"
export K3S
JQ="$(bazel run //rules/external_binary:jq_binary_location 2> /dev/null)"
export JQ
YAML2JSON="$(bazel run //rules/external_binary:yaml2json_binary_location 2> /dev/null)"
export YAML2JSON
