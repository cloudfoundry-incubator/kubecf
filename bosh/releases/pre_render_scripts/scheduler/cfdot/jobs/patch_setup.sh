#!/usr/bin/env bash
##
# ATTENTION: This is part of a set of six interconnected patches.
#            Two files spread over three instance groups.
# See
# - bosh/releases/pre_render_scripts/diego-cell/cfdot/jobs
# - bosh/releases/pre_render_scripts/diego-api/cfdot/jobs
# - bosh/releases/pre_render_scripts/scheduler/cfdot/jobs

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/cfdot/templates/setup.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Look for cfdot in the new, shared location.
sed -i "s|PATH=/var/vcap/packages|PATH=/var/vcap/data|g" "${target}"

sha256sum "${target}" > "${sentinel}"
