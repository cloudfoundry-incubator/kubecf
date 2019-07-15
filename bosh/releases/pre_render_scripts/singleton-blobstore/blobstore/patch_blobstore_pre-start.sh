#!/usr/bin/env bash

set -o errexit

# Perform a faster chown when the blobstore starts.
patch --binary --unified /var/vcap/all-releases/jobs-src/capi/blobstore/templates/pre-start.sh.erb <<'EOT'
@@ -20,14 +20,10 @@

   chown vcap:vcap $store_dir
   local dirs="$run_dir $log_dir $store_tmp_dir $data_dir $data_tmp_dir $nginx_webdav_dir ${nginx_webdav_dir}/.."
-  local num_needing_chown=$(find $dirs -not -user vcap -or -not -group vcap | wc -l)
-
-  if [ $num_needing_chown -gt 0 ]; then
-    echo "chowning ${num_needing_chown} files to vcap:vcap"
-    find $dirs -not -user vcap -or -not -group vcap | xargs chown vcap:vcap
-  else
-    echo "no chowning needed, all relevant files are vcap:vcap already"
-  fi
+  for dir in ${dirs}; do
+    echo "Setting ownership of ${dir} to vcap:vcap recursively"
+    chown --recursive vcap:vcap "${dir}"
+  done
 }

 <% if spec.bootstrap %>
EOT
