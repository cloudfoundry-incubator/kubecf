#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/cf-mysql/mysql/templates/mariadb_ctl.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  echo "Patch already applied. Skipping"
  exit 0
fi

patch --verbose "${target}" <<'EOT'
@@ -40,8 +40,6 @@
 # add perl libraries to perl env
 export PERL5LIB=$PERL5LIB:/var/vcap/packages/xtrabackup/lib/perl/5.18.2

-ulimit -n <%= p('cf_mysql.mysql.max_open_files') %>
-
 if [[ ! -d "$RUN_DIR" ]]; then
   mkdir -p $RUN_DIR
 fi
EOT

touch "${sentinel}"
