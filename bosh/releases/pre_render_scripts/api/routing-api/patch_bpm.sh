#!/usr/bin/env bash

set -o errexit

patch --binary --unified /var/vcap/all-releases/jobs-src/routing/routing-api/templates/bpm.yml.erb <<'EOT'
@@ -11,7 +11,7 @@
     - -timeFormat
     - rfc3339
     - -ip
-    - <%= spec.ip %>
+    - $(POD_IP)
     <% if p("routing_api.auth_disabled") == true %>- -devMode <% end %>

     hooks:
EOT
