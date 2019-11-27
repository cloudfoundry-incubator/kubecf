#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/routing/routing-api/templates/bpm.yml.erb"

PATCH=$(cat <<'EOT'
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
)

# Only patch once
if ! patch --reverse --binary --unified --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose --binary --unified "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
