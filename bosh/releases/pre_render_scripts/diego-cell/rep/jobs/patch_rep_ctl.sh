#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/rep/templates/rep_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -39,9 +39,6 @@
     $bin_dir/set-rep-kernel-params
     $bin_dir/setup_mounted_data_dirs

-    # Allowed number of open file descriptors
-    ulimit -n 100000
-
     exec chpst -u vcap:vcap /var/vcap/jobs/rep/bin/rep_as_vcap

     ;;
EOT

sha256sum "${target}" > "${sentinel}"
