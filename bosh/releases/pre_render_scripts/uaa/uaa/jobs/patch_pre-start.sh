#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Patch bin/pre-start.erb for the certificates to work with SUSE.
patch --verbose "${target}" <<'EOT'
--- pre-start.erb  2019-12-04 08:37:51.046503943 +0100
+++ - 2019-12-04 08:41:36.055142488 +0100
@@ -32,9 +32,29 @@
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
+      *rhel|centos|fedora*)
+        timeout --signal=KILL 180s /usr/bin/update-ca-trust
+        cp /etc/ssl/certs/ca-bundle.crt ${OS_CERTS_FILE}
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

sha256sum "${target}" > "${sentinel}"
