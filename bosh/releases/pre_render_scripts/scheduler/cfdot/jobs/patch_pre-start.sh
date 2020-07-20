#!/usr/bin/env bash
##
# ATTENTION: This is part of a set of six interconnected patches.
#            Two files spread over three instance groups.
# See
# - bosh/releases/pre_render_scripts/diego-cell/cfdot/jobs
# - bosh/releases/pre_render_scripts/diego-api/cfdot/jobs
# - bosh/releases/pre_render_scripts/scheduler/cfdot/jobs

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/cfdot/templates/pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Place the cfdot related things into a location shared by all the jobs.
##
# Implementation note: Given the small size of the pre-start script a
# patch is likely as large, or even larger than just the replacement
# script, we simply do the latter.
cat > "${target}" <<'EOT'
#!/bin/bash -e

DEST=/var/vcap/data/cfdot/bin
mkdir -p "${DEST}"

cp /var/vcap/jobs/cfdot/bin/setup     "${DEST}/cfdot.sh"
cp /var/vcap/packages/cfdot/bin/cfdot "${DEST}/cfdot"
chown root:vcap "${DEST}/cfdot.sh"
EOT

sha256sum "${target}" > "${sentinel}"
