#!/usr/bin/env bash

set -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

bazel run @kubectl//:kubectl -- delete namespace "${KUBECF_NAMESPACE}" || true
bazel run @kubectl//:kubectl -- create namespace "${KUBECF_NAMESPACE}"
