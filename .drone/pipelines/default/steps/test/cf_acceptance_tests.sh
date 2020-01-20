#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/cats_common.sh"

run_cf_acceptance_tests
exit_code="$(cat EXIT)"

if [[ "$exit_code" == "0" ]]; then
    # Complaint wrong. The echo generates a traling newline the `blue` doesn't.
    # shellcheck disable=SC2005
    echo "$(green OK)"
else
    # shellcheck disable=SC2005
    echo "$(red "FAILED")"
fi
# ... and exit the script with the container's exit code.
exit "${exit_code}"
