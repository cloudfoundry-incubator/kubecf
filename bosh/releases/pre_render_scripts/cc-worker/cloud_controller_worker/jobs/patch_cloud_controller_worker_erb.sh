#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_worker/templates/bin/cloud_controller_worker.erb"
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
 source /var/vcap/jobs/cloud_controller_worker/bin/ruby_version.sh
 source /var/vcap/jobs/cloud_controller_worker/bin/blobstore_waiter.sh
EOT

sha256sum "${target}" > "${sentinel}"
