#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/routing/routing-api/templates/bpm.yml.erb"

patch --binary --unified --verbose "${target}" <<'EOT'
@@ -11,7 +11,7 @@
     - -timeFormat
     - rfc3339
     - -ip
-    - <%= spec.ip %>
+    - 0.0.0.0
     <% if p("routing_api.auth_disabled") == true %>- -devMode <% end %>

     hooks:
EOT
