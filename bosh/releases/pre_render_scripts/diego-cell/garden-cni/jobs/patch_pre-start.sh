#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/cf-networking/garden-cni/templates/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Place the garden-external-networker into a location shared by all the jobs.
patch --verbose "${target}" <<'EOT'
@@ -1,3 +1,8 @@
 #!/bin/bash -eu

 rm -rf /var/vcap/data/garden-cni || true
+
+DEST=/var/vcap/data/runc-cni/bin/
+
+mkdir -p "${DEST}"
+cp /var/vcap/packages/runc-cni/bin/garden-external-networker "${DEST}/garden-external-networker"
EOT

sha256sum "${target}" > "${sentinel}"
