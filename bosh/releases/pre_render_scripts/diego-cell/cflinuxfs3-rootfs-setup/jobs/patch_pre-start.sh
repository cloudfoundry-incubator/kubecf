#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/cflinuxfs3/cflinuxfs3-rootfs-setup/templates/pre-start"

# Use the ephemeral data directory for the rootfs
PATCH=$(cat <<'EOT'
@@ -3,8 +3,8 @@

 CONF_DIR=/var/vcap/jobs/cflinuxfs3-rootfs-setup/config
 ROOTFS_PACKAGE=/var/vcap/packages/cflinuxfs3
-ROOTFS_DIR=$ROOTFS_PACKAGE/rootfs
-ROOTFS_TAR=$ROOTFS_PACKAGE/rootfs.tar
+ROOTFS_DIR=/var/vcap/data/rep/cflinuxfs3/rootfs
+ROOTFS_TAR=/var/vcap/data/rep/cflinuxfs3/rootfs.tar
 TRUSTED_CERT_FILE=$CONF_DIR/certs/trusted_ca.crt
 CA_DIR=$ROOTFS_DIR/usr/local/share/ca-certificates/
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi