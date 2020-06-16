#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/app-autoscaler/scalingengine/templates/scalingengine_ctl"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

sed -i "s/pid_guard/#pid_guard/g" "${target}"

sha256sum "${target}" > "${sentinel}"
