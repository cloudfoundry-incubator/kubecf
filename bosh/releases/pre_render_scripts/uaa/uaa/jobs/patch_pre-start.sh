#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/pre-start.erb"

# Patch bin/pre-start.erb for the certificates to work with SUSE.
PATCH=$(cat <<'EOT'
--- pre-start.erb  2019-12-04 08:37:51.046503943 +0100
+++ - 2019-12-04 08:41:36.055142488 +0100
@@ -32,9 +32,24 @@
     <% end %>

     log "Trying to run update-ca-certificates..."
-    # --certbundle is an undocumented flag in the update-ca-certificates script
-    # https://salsa.debian.org/debian/ca-certificates/blob/master/sbin/update-ca-certificates#L53
-    timeout --signal=KILL 180s /usr/sbin/update-ca-certificates -f -v --certbundle "$(basename "${OS_CERTS_FILE}")"
+    source /etc/os-release
+    case "${ID}" in
+      *ubuntu*)
+        # --certbundle is an undocumented flag in the update-ca-certificates script
+        # https://salsa.debian.org/debian/ca-certificates/blob/master/sbin/update-ca-certificates#L53
+        timeout --signal=KILL 180s /usr/sbin/update-ca-certificates -f -v --certbundle "$(basename "${OS_CERTS_FILE}")"
+      ;;
+
+      *suse|sles*)
+        timeout --signal=KILL 180s /usr/sbin/update-ca-certificates -f -v
+        mv /var/lib/ca-certificates/ca-bundle.pem /etc/ssl/certs/"$(basename "${OS_CERTS_FILE}")"
+      ;;
+
+      *)
+        echo "Unsupported operating system: ${PRETTY_NAME}"
+        exit 42
+      ;;
+    esac
 }

 function new_cache_files_are_identical {
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
