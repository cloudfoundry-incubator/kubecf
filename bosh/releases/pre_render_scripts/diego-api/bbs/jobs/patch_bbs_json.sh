#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/bbs/templates/bbs.json.erb"

# Advertise our spec address.
patch --verbose "${target}" <<'EOT'
62c62
<     "#{scheme}://#{name.gsub('_', '-')}-#{spec.index}.#{base}:#{port}"
---
>     "#{scheme}://#{spec.address}:#{port}"
EOT
