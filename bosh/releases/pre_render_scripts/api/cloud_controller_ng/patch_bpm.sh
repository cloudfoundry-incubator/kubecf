#!/usr/bin/env bash

set -o errexit

# Patch a few things on the BPM:
#   - DYNO environment variable is not needed.
#   - We don't enable New Relic.
#   - NGINX maintenance shouldn't run.
patch /var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/templates/bpm.yml.erb <<'EOT'
23d22
<     "DYNO" => "#{spec.job.name}-#{spec.index}",
77,78d75
<     nginx_newrelic_plugin_config,
<     nginx_maintenance_config,
EOT
