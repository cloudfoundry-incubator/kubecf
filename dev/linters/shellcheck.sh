#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

find_args=(
    -not \( -path "${workspace}/deploy/helm/kubecf/charts" -prune \)
    -name '*.sh'
)

# shellcheck disable=SC2046
# We want word splitting with find.
bazel run @shellcheck//:binary -- $(find "${workspace}" "${find_args[@]}")
