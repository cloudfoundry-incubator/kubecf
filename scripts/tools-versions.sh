#!/usr/bin/env bash
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
# shellcheck disable=SC1090
source "${GIT_ROOT}/scripts/include/setup.sh"

TOOLS+=(fubar) # XXX remove; for testing

# Add additional tool dependencies from the internal tool definitions.
for tool in "${TOOLS[@]}"; do
    # shellcheck disable=SC2207
    TOOLS+=($(var_lookup "${tool}_requires"))
done

# Sort tools alphabetically and remove duplicates.
# shellcheck disable=SC2207
TOOLS=($(printf '%s\n' "${TOOLS[@]}" | sort | uniq))

for tool in "${TOOLS[@]}"; do
    tool_status "${tool}"
    # Don't show internal tools unless VERBOSE is set.
    if [[ -n "${VERBOSE:-}" || ! "${TOOL_STATUS}" =~ is[[:space:]]internal ]]; then
        echo "${TOOL_STATUS}"
    fi
done
