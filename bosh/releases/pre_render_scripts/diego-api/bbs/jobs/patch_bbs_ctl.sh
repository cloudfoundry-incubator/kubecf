#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/bbs/templates/bbs_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -26,14 +26,6 @@

     $bin_dir/set-bbs-kernel-params

-    # Allowed number of open file descriptors (must be a positive integer)
-    <%
-    if !p('limits.open_files').is_a?(Integer) || p('limits.open_files') <= 0
-      raise "limits.open_files must be a positive integer"
-    end
-    %>
-    ulimit -n <%= p('limits.open_files') %>
-
     exec chpst -u vcap:vcap bash -c  '/var/vcap/jobs/bbs/bin/bbs_as_vcap'

     ;;
EOT

sha256sum "${target}" > "${sentinel}"
