#!/usr/bin/env bash

set -o errexit

# shellcheck disable=SC2046
# We want word splitting with find.
bazel run //dev/linters:yamllint -- \
      -d "{extends: relaxed, rules: {line-length: {max: 120}}}" \
      --strict $(find . -type f \
                      -path "./deploy/helm/kubecf/values.*" \
                      -or -not -path "./deploy/helm/kubecf/*" \
                      -name '*.yaml' -or -name '*.yml')
