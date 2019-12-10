#!/usr/bin/env sh

# This script wraps the original drone-server executable but maps the provided $PORT environment
# variable to the $DRONE_SERVER_PORT variable.

set -o errexit -o nounset

export DRONE_SERVER_PORT=":${PORT}"

exec /bin/drone-server "${@}"
