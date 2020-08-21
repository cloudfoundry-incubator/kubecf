#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools shellcheck

find_args=(
    -not \( -path "./chart/charts" -prune \)
    -not \( -path "./output" -prune \)
    -not \( -path "./src" -prune \)
    -name '*.sh'
)

# shellcheck disable=SC2046
# We want word splitting with find.
# Ignore all submodule files under output/ and under src/.
shellcheck $(find . "${find_args[@]}")
