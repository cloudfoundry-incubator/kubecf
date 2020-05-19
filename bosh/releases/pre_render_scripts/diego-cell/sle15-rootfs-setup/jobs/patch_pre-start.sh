#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/sle15/sle15-rootfs-setup/templates/pre-start"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Use the ephemeral data directory for the rootfs
patch --verbose "${target}" <<'EOT'
@@ -3,8 +3,8 @@

 CONF_DIR=/var/vcap/jobs/sle15-rootfs-setup/config
 ROOTFS_PACKAGE=/var/vcap/packages/sle15
-ROOTFS_DIR=$ROOTFS_PACKAGE/rootfs
-ROOTFS_TAR=$ROOTFS_PACKAGE/rootfs.tar
+ROOTFS_DIR=/var/vcap/data/rep/sle15/rootfs
+ROOTFS_TAR=/var/vcap/data/rep/sle15/rootfs.tar
EOT

sha256sum "${target}" > "${sentinel}"
