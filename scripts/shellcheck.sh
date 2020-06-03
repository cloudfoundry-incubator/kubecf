#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools shellcheck

# shellcheck disable=SC2046
# We want word splitting with find.
# Ignore all submodule files under output/ and under src/.
shellcheck $(find . -name src -prune -o -name output -prune -o -name '*.sh' -print)
