#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cc_uploader/templates/pre-start.erb"

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
