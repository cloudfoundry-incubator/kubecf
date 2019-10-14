#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/templates/bpm.yml.erb"

# Patch a few things on the BPM:
#   - DYNO environment variable is not needed.
#   - We don't enable New Relic.
#   - NGINX maintenance shouldn't run.
PATCH=$(cat <<'EOT'
@@ -20,7 +20,6 @@
     "BUNDLE_GEMFILE" => "/var/vcap/packages/cloud_controller_ng/cloud_controller_ng/Gemfile",
     "CLOUD_CONTROLLER_NG_CONFIG" => "/var/vcap/jobs/cloud_controller_ng/config/cloud_controller_ng.yml",
     "C_INCLUDE_PATH" => "/var/vcap/packages/libpq/include",
-    "DYNO" => "#{spec.job.name}-#{spec.index}",
     "HOME" => "/home/vcap",
     "LANG" => "en_US.UTF-8",
     "LIBRARY_PATH" => "/var/vcap/packages/libpq/lib",
@@ -79,8 +78,6 @@
   "processes" => [
     cloud_controller_ng_config,
     nginx_config,
-    nginx_newrelic_plugin_config,
-    nginx_maintenance_config,
     ccng_monit_http_healthcheck_config,
   ]
 }
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
