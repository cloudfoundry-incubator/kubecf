#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/locket/templates/locket_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -26,9 +26,6 @@

     $bin_dir/set-locket-kernel-params

-    # Allowed number of open file descriptors
-    ulimit -n 100000
-
     exec chpst -u vcap:vcap bash -c  '/var/vcap/jobs/locket/bin/locket_as_vcap'

     ;;
EOT

sha256sum "${target}" > "${sentinel}"
