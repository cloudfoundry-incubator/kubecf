#!/usr/bin/env bash

set -o errexit -o nounset

# Add internal_server_name property so it can be injected.

target="/var/vcap/all-releases/jobs-src/capi/blobstore/job.MF"

patch --binary --unified --verbose "${target}" <<'EOT'
@@ -95,2 +95,5 @@
   domain:
     description: "DEPRECATED: The system domain.  The public server will listen on host 'blobstore.system-domain.tld'"
+
+  internal_server_name:
+    description: "The internal server_name"
EOT
