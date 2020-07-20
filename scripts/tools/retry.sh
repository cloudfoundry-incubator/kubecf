# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(retry)

function retry {
    # Usage: [RETRIES=3] [DELAY=5] retry [command...]
    local max="${RETRIES:-3}"
    local delay="${DELAY:-5}"
    local i=0

    while test "${i}" -lt "${max}" ; do
        printf "%s/%s: %s\\n" "$(( i + 1 ))" "${max}" "$*"
        if "$@" ; then
            return
        fi
        sleep "${delay}"
        i="$(( i + 1 ))"
    done
    return 1
}
