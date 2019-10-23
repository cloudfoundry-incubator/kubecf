#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/bbs/templates/bbs.json.erb"

# Advertise our spec address.
PATCH=$(cat <<'EOT'
62c62
<     "#{scheme}://#{name.gsub('_', '-')}-#{spec.index}.#{base}:#{port}"
---
>     "#{scheme}://#{spec.address}:#{port}"
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
