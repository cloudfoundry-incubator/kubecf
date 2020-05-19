#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/file_server/templates/file_server_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -20,9 +20,6 @@

     $bin_dir/set-file-server-kernel-params

-    # Allowed number of open file descriptors
-    ulimit -n 100000
-
     exec chpst -u vcap:vcap bash -c '/var/vcap/jobs/file_server/bin/file_server_as_vcap'

     ;;
EOT

sha256sum "${target}" > "${sentinel}"
