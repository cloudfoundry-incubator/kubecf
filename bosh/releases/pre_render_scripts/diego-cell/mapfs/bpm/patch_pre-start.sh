#!/usr/bin/env bash

function patch() {
    local target="${1}"
    local sentinel="${1}.patch_sentinel"
    if [[ -r "${sentinel}" ]]; then
        if sha256sum --check "${sentinel}" ; then
            echo "Patch already applied. Skipping ${target}"
            return 0
        fi
        echo "Sentinel mismatch, re-patching ${target}"
    fi
    command patch --verbose --batch --strip=1 "${target}" # << STDIN
}

patch "/var/vcap/all-releases/jobs-src/mapfs/mapfs/templates/install.erb" <<"EOP"
diff --git a/jobs/mapfs/templates/install.erb b/jobs/mapfs/templates/install.erb
index dade2b9..885cb84 100644
--- a/jobs/mapfs/templates/install.erb
+++ b/jobs/mapfs/templates/install.erb
@@ -52,9 +52,12 @@ user_allow_other
 EOF
 chmod 644 /etc/fuse.conf
 
+<% end %>
+
 echo "Installing mapfs"
 
 chown root:vcap /var/vcap/packages/mapfs/bin/mapfs
 chmod 750 /var/vcap/packages/mapfs/bin/mapfs
 chmod u+s /var/vcap/packages/mapfs/bin/mapfs
-<% end %>
\ No newline at end of file
+
+cp /var/vcap/packages/mapfs/bin/mapfs /var/vcap/jobs/mapfs/bin/mapfs
EOP
