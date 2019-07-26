#!/usr/bin/env bash

set -o errexit -o nounset

# Fix the hardcoded server_name.

target="/var/vcap/all-releases/jobs-src/capi/blobstore/templates/blobstore.conf.erb"

patch --binary --unified --verbose "${target}" <<'EOT'
@@ -13,7 +13,7 @@
 # Internal server
 server {
   listen      <%= p('blobstore.tls.port') %> ssl;
-  server_name blobstore.service.cf.internal;
+  server_name <%= p("internal_server_name") %>;
   ssl_certificate     /var/vcap/jobs/blobstore/ssl/blobstore.crt;
   ssl_certificate_key /var/vcap/jobs/blobstore/ssl/blobstore.key;
EOT
