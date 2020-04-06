# shellcheck shell=bash

set -o errexit -o nounset -o pipefail

cd "${GIT_ROOT}"

for INCLUDE in defaults helpers tools versions; do
    # shellcheck disable=SC1090
    source "scripts/include/${INCLUDE}.sh"
done

# COLOR defaults to true if stdout is a tty.
if [[ -z "${COLOR:-}" && -t 1 ]]; then
    COLOR=true
fi

if [ -n "${XTRACE:-}" ]; then
    set -o xtrace
fi

# NO_PINNED_TOOLS exists only for debugging tooling scripts.
if [ -z "${NO_PINNED_TOOLS:-}" ]; then
    export PATH="${TOOLS_DIR}:${PATH}"
fi
