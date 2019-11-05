#!/usr/bin/env bash

set -o errexit

# shellcheck disable=SC2046
# We want word splitting with find.
bazel run @shellcheck//shellcheck -- $(find . -name '*.sh')
