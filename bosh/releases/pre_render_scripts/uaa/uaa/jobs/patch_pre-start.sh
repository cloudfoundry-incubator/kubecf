#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/pre-start.erb"

# Patch bin/pre-start.erb for the certificates to work with SUSE.
PATCH=$(cat <<'EOT'
--- pre-start.erb	2019-11-05 10:53:19.000000000 +0100
+++ -	2019-11-05 10:59:27.000000000 +0100
@@ -21,11 +21,29 @@
 }

 # add certs from manifest to OS certs
-rm -f /usr/local/share/ca-certificates/uaa_*
+source /etc/os-release
+case "${ID}" in
+  *ubuntu*)
+    rm -f /usr/local/share/ca-certificates/uaa_*
 <% p('uaa.ca_certs', []).each_with_index do |cert, i| %>
     echo "Adding certificate from manifest to OS certs /usr/local/share/ca-certificates/uaa_<%= i %>.crt"
     echo -n '<%= cert %>' >> "/usr/local/share/ca-certificates/uaa_<%= i %>.crt"
 <% end %>
+  ;;
+
+  *suse*)
+    rm -f /etc/pki/trust/anchors/uaa_*
+<% p('uaa.ca_certs', []).each_with_index do |cert, i| %>
+    echo "Adding certificate from manifest to OS certs /etc/pki/trust/anchors/uaa_<%= i %>.crt"
+    echo -n '<%= cert %>' >> "/etc/pki/trust/anchors/uaa_<%= i %>.crt"
+<% end %>
+  ;;
+
+  *)
+  echo "Unsupported operating system: ${PRETTY_NAME}"
+  exit 42
+  ;;
+esac

 update_ca_certificate

EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
