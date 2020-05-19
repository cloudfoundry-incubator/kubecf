#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/bbs/templates/bbs.json.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Advertise our spec address.
patch --verbose "${target}" <<'EOT'
62c62
<     "#{scheme}://#{name.gsub('_', '-')}-#{spec.index}.#{base}:#{port}"
---
>     "#{scheme}://#{spec.address}:#{port}"
EOT

sha256sum "${target}" > "${sentinel}"
