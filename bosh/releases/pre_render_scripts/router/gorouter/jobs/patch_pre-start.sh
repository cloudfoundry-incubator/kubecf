#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/routing/gorouter/templates/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
--- pre-start.erb  2019-12-12 13:56:59.944789605 +0100
+++ -  2019-12-12 13:57:07.384803023 +0100
@@ -28,9 +28,6 @@
     echo "Not setting /proc/sys/net/ipv4 parameters, since I'm running inside a linux container"
 <% end %>

-# Allowed number of open file descriptors
-ulimit -n 100000
-
 # Add jq to path
 cp /var/vcap/jobs/gorouter/bin/setup-jq /etc/profile.d/jq.sh
 chown root:vcap /etc/profile.d/jq.sh
EOT

sha256sum "${target}" > "${sentinel}"
