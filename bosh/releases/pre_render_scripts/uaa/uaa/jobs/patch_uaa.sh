#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/uaa.erb"

# Patch bin/uaa.erb for the certificates to work with SUSE.
PATCH=$(cat <<'EOT'
--- uaa.erb    2019-11-06 21:27:49.000000000 +0100
+++ -     2019-11-06 21:42:06.000000000 +0100
@@ -46,7 +46,22 @@

 echo "`date` [uaa] UAA Preparing Certs"
 CERT_FILE="/tmp/ca-certificates.crt"
-cp /etc/ssl/certs/ca-certificates.crt "$CERT_FILE"
+
+source /etc/os-release
+case "${ID}" in
+  *ubuntu*)
+    cp /etc/ssl/certs/ca-certificates.crt "$CERT_FILE"
+    ;;
+
+  *suse*)
+    cp /var/lib/ca-certificates/ca-bundle.pem "$CERT_FILE"
+    ;;
+
+  *)
+    echo "Unsupported operating system: ${PRETTY_NAME}"
+    exit 42
+    ;;
+esac

 CONF_DIR="/var/vcap/jobs/uaa/config"
 CACHE_DIR="/var/vcap/data/uaa/cert-cache"
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
