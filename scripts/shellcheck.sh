#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools shellcheck

# shellcheck disable=SC2046
# We want word splitting with find.
# Ignore all submodule files under output/ and under src/.
shellcheck $(find . \
                  -not \( -path ./src -prune \) \
                  -not \( -path ./output -prune \) \
                  -name '*.sh')
