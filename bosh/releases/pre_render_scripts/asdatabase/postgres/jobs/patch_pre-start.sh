#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/postgres/postgres/templates/pre-start.sh.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  echo "Patch already applied. Skipping"
  exit 0
fi

sed -i "s/sysctl/#sysctl/g" "${target}"

touch "${sentinel}"
