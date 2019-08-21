#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/templates/post-start.sh.erb"

# chown the cc log so that the vcap user can write to it from the post-start script.
patch --verbose "${target}" <<'EOT'
@@ -61,6 +61,7 @@
 }

 function main {
+  chown vcap:vcap "/var/vcap/sys/log/cloud_controller_ng/cloud_controller_ng.log"
   install_buildpacks
   fix_bundler_home_permissions
 }
EOT
