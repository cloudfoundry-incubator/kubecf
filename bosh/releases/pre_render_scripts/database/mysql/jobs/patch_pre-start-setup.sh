#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/cf-mysql/mysql/templates/pre-start-setup.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  echo "Patch already applied. Skipping"
  exit 0
fi

# Patch pre-start-setup.erb to:
# 1. Remove ulimit call.
# 2. Play nice with BPM's persistent disk. Instead of checking for the existence of the directory
# /var/vcap/store/mysql, it checks for the existence of the file
# /var/vcap/store/mysql/setup_succeeded, which is also created in a command from this patch.
patch --verbose "${target}" <<'EOT'
@@ -50,8 +50,6 @@
 ln -sf $MARIADB_JOB_DIR/config/disable_mysql_cli_history.sh /etc/profile.d/disable_mysql_cli_history.sh
 <% end %>

-ulimit -n <%= p('cf_mysql.mysql.max_open_files') %>
-
 <% if p('cf_mysql.mysql.disable_auto_sst') %>
 if [ -d ${datadir} ]; then
   export DISABLE_SST=1
@@ -79,14 +77,15 @@
 check_mysql_disk_persistence
 check_mysql_disk_capacity

-if ! test -d ${datadir}; then
-  log "pre-start setup script: making ${datadir} and running /var/vcap/packages/mariadb/scripts/mysql_install_db"
-  mkdir -p ${datadir}
+setup_control_file="${datadir}/setup_succeeded"
+if ! test -e "${setup_control_file}"; then
+  log "pre-start setup script: running /var/vcap/packages/mariadb/scripts/mysql_install_db"
   /var/vcap/packages/mariadb/scripts/mysql_install_db \
          --defaults-file=/var/vcap/jobs/mysql/config/my.cnf \
          --basedir=/var/vcap/packages/mariadb \
          --user=vcap \
          --datadir=${datadir} >> $LOG_FILE 2>> $LOG_FILE
+  touch "${setup_control_file}"
 fi
 chown -R vcap:vcap ${datadir}
EOT

touch "${sentinel}"
