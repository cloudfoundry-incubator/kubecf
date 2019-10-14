#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/routing/routing-api/templates/bpm.yml.erb"

PATCH=$(cat <<'EOT'
@@ -11,7 +11,7 @@
     - -timeFormat
     - rfc3339
     - -ip
-    - <%= spec.ip %>
+    - 0.0.0.0
     <% if p("routing_api.auth_disabled") == true %>- -devMode <% end %>

     hooks:
EOT
)

# Only patch once
if ! patch --reverse --binary --unified --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose --binary --unified "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
