#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cc_uploader/templates/cc_uploader_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -40,9 +40,6 @@
         echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
     fi

-    # Allowed number of open file descriptors
-    ulimit -n 100000
-
     # Work around for GOLANG 1.5.3 DNS bug
     export GODEBUG=netdns=cgo
EOT

sha256sum "${target}" > "${sentinel}"
