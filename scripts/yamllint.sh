#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools yamllint

find_args=(
    # Don't lint the helm subcharts; they are imported.
    -not \( -path "./chart/charts" -prune \)

    # Don't lint any generated output files.
    -not \( -path "./output" -prune \)

    # Don't lint submodules.
    -not \( -path "./src" -prune \)

    # Only lint values.yaml file in the kubecf static files
    # the rest contain template expressions that must be
    # evaluated before the files become valid YAML.
    \( -path "./chart/values.*"
       -or
       -path "./chart/config/*"
       -or
       -not -path "./chart/*"
    \)
    \( -path "./mixins/*/values.*"
       -or
       -path "./mixins/*/config/*"
       -or
       -not -path "./mixins/*"
    \)
    \( -path "./tests/config/values.*"
       -or
       -not -path "./tests/config/*"
    \)

    # Check both file extensions, although we should have only .yaml files.
    \( -name '*.yaml' -or -name '*.yml' \)
)

# shellcheck disable=SC2046
# We want word splitting with find.
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" \
         --strict $(find . "${find_args[@]}")
