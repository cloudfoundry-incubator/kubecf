#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# shellcheck disable=SC2046
# We want word splitting with find.
bazel run //dev/linters/yamllint -- \
      -d "{extends: relaxed, rules: {line-length: {max: 120}}}" \
      --strict $(find "${workspace}" -type f \
                      -path "${workspace}/deploy/helm/kubecf/values.*" \
                      -or -not -path "${workspace}/deploy/helm/kubecf/*" \
                      -name '*.yaml' -or -name '*.yml')
