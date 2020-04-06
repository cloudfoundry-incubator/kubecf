#!/usr/bin/env bash
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
# shellcheck disable=SC1090
source "${GIT_ROOT}/scripts/include/setup.sh"

# Make sure we have an exact version match for *all* defined tools.
PINNED_TOOLS=true require_tools "${TOOLS[@]}"
