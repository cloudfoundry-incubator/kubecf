#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools yamllint

find_args=(
    -not \( -path "./deploy/helm/kubecf/charts" -prune \)
    -not \( -path "./output" -prune \)
    -not \( -path "./src" -prune \)
    \( -path "./deploy/helm/kubecf/values.*"
       -or
       -not -path "./deploy/helm/kubecf/*"
    \)
    \( -name '*.yaml' -or -name '*.yml' \)
)

# shellcheck disable=SC2046
# We want word splitting with find.
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" \
         --strict $(find . "${find_args[@]}")
