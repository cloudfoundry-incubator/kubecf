#!/usr/bin/env bash

set -o errexit

# Patch pre-start-setup.erb to play nice with BPM's persistent disk. Instead of checking for the
# existence of the directory /var/vcap/store/mysql, it checks for the existence of the file
# /var/vcap/store/mysql/setup_succeeded, which is also created in a command from this patch.
patch /var/vcap/all-releases/jobs-src/cf-mysql/mysql/templates/pre-start-setup.erb <<'EOT'
82,84c82,84
< if ! test -d ${datadir}; then
<   log "pre-start setup script: making ${datadir} and running /var/vcap/packages/mariadb/scripts/mysql_install_db"
<   mkdir -p ${datadir}
---
> setup_control_file="${datadir}/setup_succeeded"
> if ! test -e "${setup_control_file}"; then
>   log "pre-start setup script: running /var/vcap/packages/mariadb/scripts/mysql_install_db"
89a90
>   touch "${setup_control_file}"
EOT
