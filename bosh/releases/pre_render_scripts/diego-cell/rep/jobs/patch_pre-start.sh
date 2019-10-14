#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/rep/templates/bpm-pre-start.erb"

# Use the ephemeral data directory for the rootfs.
PATCH=$(cat <<'EOT'
@@ -5,3 +5,7 @@
 $bin_dir/set-rep-kernel-params

 $bin_dir/setup_mounted_data_dirs
+
+mkdir -p /var/vcap/data/shared-packages/
+cp -r /var/vcap/packages/healthcheck /var/vcap/data/shared-packages/
+cp -r /var/vcap/packages/proxy /var/vcap/data/shared-packages/
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi