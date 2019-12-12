#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/cf-mysql/mysql/templates/galera-healthcheck_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  echo "Patch already applied. Skipping"
  exit 0
fi

patch --verbose "${target}" <<'EOT'
@@ -24,8 +24,6 @@

     cd $package_dir

-    ulimit -n <%= p('cf_mysql.mysql.max_open_files') %> # HIGH Ulimit for SST of lots of tables (in case we run the bootstrap errand)
-
     chpst -u vcap:vcap bash -c "
       $package_dir/bin/galera-healthcheck \
         -configPath=$job_dir/config/galera_healthcheck_config.yaml \

EOT

touch "${sentinel}"
