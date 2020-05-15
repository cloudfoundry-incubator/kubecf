#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cc_uploader/templates/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Remove sysctl calls as we are running in containers.
# cc_uploader_ctl in https://github.com/cloudfoundry/capi-release/blob/master/jobs/cc_uploader/templates/cc_uploader_ctl.erb#L26
# also skips setting those parameters.
patch --verbose "${target}" <<'EOT'
@@ -6,6 +6,3 @@
     /var/vcap/jobs/bosh-dns/bin/wait
   fi
 fi
-
-sysctl -e -w net.ipv4.tcp_fin_timeout=10
-sysctl -e -w net.ipv4.tcp_tw_reuse=1
EOT

sha256sum "${target}" > "${sentinel}"
