#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# shellcheck disable=SC2046
# We want word splitting with find.
bazel run @shellcheck//:binary -- \
      $(find "${workspace}" -name '*.sh' | grep -v '/_work/')
