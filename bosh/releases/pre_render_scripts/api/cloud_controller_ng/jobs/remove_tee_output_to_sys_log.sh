#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/templates/pre-start.sh.erb"

# TODO: Figure out why tee_output_to_sys_log fails the pre-start.
patch --verbose "${target}" <<'EOT'
7d6
< tee_output_to_sys_log "cloud_controller_ng.$(basename "$0")"
EOT
