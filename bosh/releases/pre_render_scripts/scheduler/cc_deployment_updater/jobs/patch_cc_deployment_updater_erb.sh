#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cc_deployment_updater/templates/bin/cc_deployment_updater.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Advertise our spec address.
patch --verbose "${target}" <<'EOT'
@@ -1,5 +1,8 @@
 #!/usr/bin/env bash

+# CAPI makes cf4k8s assumptions when running on k8s that are not correct for kubecf
+unset KUBERNETES_SERVICE_HOST
+
 source /var/vcap/jobs/cc_deployment_updater/bin/ruby_version.sh
 cd /var/vcap/packages/cloud_controller_ng/cloud_controller_ng
 exec bundle exec rake deployment_updater:start
EOT

sha256sum "${target}" > "${sentinel}"
