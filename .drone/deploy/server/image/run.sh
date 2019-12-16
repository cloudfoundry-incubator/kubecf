#!/usr/bin/env sh

# This script wraps the original drone-server executable but maps the provided $PORT environment
# variable to the $DRONE_SERVER_PORT variable as well as runs the the Starlark plugin.

set -o errexit -o nounset

# DRONE_CONVERT_PLUGIN_SECRET is required, but in this case it is running inside the container with
# no public access, so we don't need a real secret.
convert_starlark_secret="dont_need_to_be_secret"
DRONE_SECRET="${convert_starlark_secret}" exec /bin/drone-convert-starlark &

export DRONE_SERVER_PORT=":${PORT}"
export DRONE_CONVERT_PLUGIN_ENDPOINT=http://127.0.0.1:3000
DRONE_CONVERT_PLUGIN_SECRET="${convert_starlark_secret}"
export DRONE_CONVERT_PLUGIN_SECRET

exec /bin/drone-server "${@}"
