# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(retry)

function retry {
    # Usage: [RETRIES=3] [DELAY=5] retry [command...]
    local max="${RETRIES:-3}"
    local delay="${DELAY:-5}"
    local i=0

    local cr
    local nl
    if [ -t 1 ]; then
        # Output is to a TTY; don't scroll display while waiting.
        cr="\r"
        # Display a trailing space between the last character and the cursor.
        # Also overwrites trailing character when number of seconds shrink from
        # two to one digit, e.g. "1m 58s" → "2m 3s".
        nl=" "
    else
        # Output is to a file; don't overwrite lines.
        cr=""
        nl="\n"
    fi

    while test "${i}" -lt "${max}" ; do
        printf "${cr}[%dm %ds] %s/%s: %s${nl}" \
               "$(( SECONDS / 60 ))" "$(( SECONDS % 60))"\
               "$(( i + 1 ))" "${max}" \
               "$*"
        if "$@" &> /dev/null ; then
            [ -n "${cr}" ] && printf "\n"
            return
        fi
        sleep "${delay}"
        i="$(( i + 1 ))"
    done
    [ -n "${cr}" ] && printf "\n"
    return 1
}
