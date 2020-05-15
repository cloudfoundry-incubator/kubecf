#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/ssh_proxy/templates/ssh_proxy_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -18,9 +18,6 @@
     mkdir -p $log_dir
     chown -R vcap:vcap $log_dir

-    # Allowed number of open file descriptors
-    ulimit -n 100000
-
     exec chpst -u vcap:vcap bash -c '/var/vcap/jobs/ssh_proxy/bin/ssh_proxy_as_vcap'

     ;;
EOT

sha256sum "${target}" > "${sentinel}"
