#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools yamllint

# shellcheck disable=SC2046
# We want word splitting with find.
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" \
         --strict $(find . \
                         -not \( -path ./src -prune \) \
                         -not \( -path ./output -prune \) \
                         -not \( -path ./deploy/helm/kubecf -prune \) \
                         \( -name '*.yml' -o -name '*.yaml' \))
