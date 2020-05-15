#!/usr/bin/env bash

set -o errexit -o nounset

# Remove /var/vcap/packages from chowing.

target="/var/vcap/all-releases/jobs-src/capi/blobstore/templates/pre-start.sh.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -9,7 +9,6 @@
   local data_dir=/var/vcap/data/blobstore
   local store_tmp_dir=$store_dir/tmp/uploads
   local data_tmp_dir=$data_dir/tmp/uploads
-  local nginx_webdav_dir=/var/vcap/packages/nginx_webdav

   mkdir -p $run_dir
   mkdir -p $log_dir
@@ -19,7 +18,7 @@
   mkdir -p $data_tmp_dir

   chown vcap:vcap $store_dir
-  local dirs="$run_dir $log_dir $store_tmp_dir $data_dir $data_tmp_dir $nginx_webdav_dir ${nginx_webdav_dir}/.."
+  local dirs="$run_dir $log_dir $store_tmp_dir $data_dir $data_tmp_dir"
   local num_needing_chown=$(find $dirs -not -user vcap -or -not -group vcap | wc -l)

   if [ $num_needing_chown -gt 0 ]; then
EOT

sha256sum "${target}" > "${sentinel}"
