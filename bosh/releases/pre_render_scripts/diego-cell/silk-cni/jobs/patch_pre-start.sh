#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/silk/silk-cni/templates/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Place the silk-cni related things into a location shared by all the jobs.
patch --verbose "${target}" <<'EOT'
@@ -4,3 +4,8 @@
 /var/vcap/packages/silk-cni/bin/cni-teardown \
   --config /var/vcap/jobs/silk-cni/config/teardown-config.json
 <% end %>
+
+DEST=/var/vcap/data/silk-cni/bin
+
+mkdir -p "${DEST}"
+cp /var/vcap/packages/silk-cni/bin/* "${DEST}/"
EOT

sha256sum "${target}" > "${sentinel}"
