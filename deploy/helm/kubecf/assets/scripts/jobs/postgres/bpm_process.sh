#!/usr/bin/env bash

set -o errexit -o nounset

wait_for_file() {
  local file_path="$1"
  local timeout="${2:-30}"
  timeout "${timeout}" bash -c "until [[ -f '${file_path}' ]]; do sleep 1; done"
  return 0
}

# shellcheck disable=SC1091
source /var/vcap/jobs/postgres/bin/pgconfig.sh

# fixes permissions issue for autoscaler db.
# https://github.com/cloudfoundry-incubator/kubecf/issues/408
chmod --recursive 0700 /var/vcap/store/postgres/

/var/vcap/jobs/postgres/bin/postgres_ctl start
wait_for_file "${PIDFILE}" || {
  echo "${PIDFILE} did not get created"
  exit 1
}
trap '/var/vcap/jobs/postgres/bin/postgres_ctl stop' EXIT

/var/vcap/jobs/postgres/bin/pg_janitor_ctl start &

tail \
  --pid "$(cat "${PIDFILE}")" \
  --follow \
  "${LOG_DIR}/startup.log" \
  "${LOG_DIR}/pg_janitor_ctl.log" \
  "${LOG_DIR}/pg_janitor_ctl.err.log"
