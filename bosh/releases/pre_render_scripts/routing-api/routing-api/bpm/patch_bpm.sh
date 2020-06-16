#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/routing/routing-api/templates/bpm.yml.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -11,8 +11,10 @@
     - -timeFormat
     - rfc3339
     - -ip
-    - <%= spec.ip %>
+    - "$(POD_IP)"
     <% if p("routing_api.auth_disabled") == true %>- -devMode <% end %>
+    env:
+      POD_IP: 0.0.0.0 # Set by k8s using an ops-file with cf-operator.

     hooks:
       pre_start: /var/vcap/jobs/routing-api/bin/bpm-pre-start
EOT

sha256sum "${target}" > "${sentinel}"
