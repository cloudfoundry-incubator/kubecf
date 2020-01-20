#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# Using git ls-files ensures that .gitignored files are skipped.
# sed: We need absolute paths for bazel
# We want work splitting with ls-files.
# shellcheck disable=SC2046
bazel run @shellcheck//:binary -- \
      $(git ls-files | awk '/.sh$/ { print $0 }' | sed -e "s|^|${workspace}/|")
