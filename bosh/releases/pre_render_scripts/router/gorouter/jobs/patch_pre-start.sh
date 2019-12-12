#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/routing/gorouter/templates/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  echo "Patch already applied. Skipping"
  exit 0
fi

patch --verbose "${target}" <<'EOT'
@@ -27,6 +27,3 @@
 <% else %>
     echo "Not setting /proc/sys/net/ipv4 parameters, since I'm running inside a linux container"
 <% end %>
-
-# Allowed number of open file descriptors
-ulimit -n 100000
EOT

touch "${sentinel}"
