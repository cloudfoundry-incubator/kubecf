#!/usr/bin/env bash

set -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

bazel run @kubectl//:kubectl -- delete namespace "${KUBECF_NAMESPACE}"
bazel run @kubectl//:kubectl -- create namespace "${KUBECF_NAMESPACE}"
bazel run @kubectl//:kubectl -- delete namespace "${CF_OPERATOR_NAMESPACE}"
bazel run @kubectl//:kubectl -- create namespace "${CF_OPERATOR_NAMESPACE}"
