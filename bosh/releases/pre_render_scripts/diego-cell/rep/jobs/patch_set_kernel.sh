#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/rep/templates/set-rep-kernel-params.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Disable ubuntu-specific uncontainerized connection limit.
patch --verbose "${target}" <<'EOT'
@@ -18,8 +18,8 @@
 
 # NF_CONNTRACK_MAX
 # Default value is 65536. We set it to a larger number to avoid running out of connections.
-modprobe nf_conntrack
-echo 262144 > /proc/sys/net/netfilter/nf_conntrack_max
+#modprobe nf_conntrack
+#echo 262144 > /proc/sys/net/netfilter/nf_conntrack_max
 
 echo 2147483647 > /proc/sys/fs/inotify/max_user_watches
 echo 2147483647 > /proc/sys/fs/inotify/max_user_instances
EOT

sha256sum "${target}" > "${sentinel}"
