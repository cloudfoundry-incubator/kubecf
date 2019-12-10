#!/usr/bin/env sh

set -o errexit -o nounset

export DRONE_SERVER_PORT=":${PORT}"

/bin/drone-server "${@}"
