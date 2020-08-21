#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/garden-runc/garden/templates/bin/bpm-pre-start.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Patch the pre-start script to setup /var/vcap/data
patch --verbose "${target}" <<'EOT'
2a3,4
> find /var/vcap/data/grootfs/ -iname '*' -delete
> 
20a23,25
> 
> # Ensure that runc and container processes can stat everything
> chmod ugo+rx /var/vcap/data/grootfs
EOT

sha256sum "${target}" > "${sentinel}"
