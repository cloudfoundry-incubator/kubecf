#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/templates/bpm.yml.erb"

# Patch a few things on the BPM:
#   - DYNO environment variable is not needed.
#   - We don't enable New Relic.
#   - NGINX maintenance shouldn't run.
PATCH=$(cat <<'EOT'
23d22
<     "DYNO" => "#{spec.job.name}-#{spec.index}",
77,78d75
<     nginx_newrelic_plugin_config,
<     nginx_maintenance_config,
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
