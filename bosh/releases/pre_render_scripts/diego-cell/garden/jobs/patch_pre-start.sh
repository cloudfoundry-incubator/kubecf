#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/garden-runc/garden/templates/bin/pre-start"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
--- jobs/garden/templates/bin/pre-start
+++ jobs/garden/templates/bin/pre-start
@@ -4,7 +4,5 @@ set -e

 source /var/vcap/jobs/garden/bin/envs
 source /var/vcap/jobs/garden/bin/grootfs-utils
-source /var/vcap/packages/greenskeeper/bin/system-preparation

-permit_device_control
 invoke_thresholder
EOT

sha256sum "${target}" > "${sentinel}"
