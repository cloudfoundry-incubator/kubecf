#!/usr/bin/env bash
source scripts/include/setup.sh

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
    STATUS="$(tool_status "${tool}")" || true
    # Don't show internal tools unless VERBOSE is set.
    if [[ -n "${VERBOSE:-}" || ! "${STATUS}" =~ is[[:space:]]internal ]]; then
        echo "${STATUS}"
    fi
done
