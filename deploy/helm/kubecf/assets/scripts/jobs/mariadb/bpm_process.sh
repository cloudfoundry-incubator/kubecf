#!/usr/bin/env bash

set -o errexit -o nounset

wait_for_file() {
  local file_path="$1"
  local timeout="${2:-30}"
  timeout "${timeout}" bash -c "until [[ -f '${file_path}' ]]; do sleep 1; done"
  return 0
}

/var/vcap/jobs/mysql/bin/mariadb_ctl start

pid_file="/var/vcap/sys/run/mysql/mysql.pid"
log_file="/var/vcap/sys/log/mysql/mariadb_ctrl.combined.log"

wait_for_file "${pid_file}" || {
  echo "${pid_file} did not get created"
  exit 1
}

wait_for_file "${log_file}" || {
  echo "${log_file} did not get created"
  exit 1
}

tail \
  --pid "$(cat "${pid_file}")" \
  --follow "${log_file}"
