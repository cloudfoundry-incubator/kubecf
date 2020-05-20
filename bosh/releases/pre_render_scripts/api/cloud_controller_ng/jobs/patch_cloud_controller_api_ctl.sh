#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/templates/cloud_controller_api_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -53,8 +53,6 @@
   start)
     setup_environment

-    ulimit -c unlimited
-
     pid_guard "$PIDFILE" "Cloud controller ng"

     exec /var/vcap/jobs/cloud_controller_ng/bin/cloud_controller_ng
EOT

sha256sum "${target}" > "${sentinel}"
