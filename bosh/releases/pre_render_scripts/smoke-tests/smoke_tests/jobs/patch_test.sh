#!/usr/bin/env bash

target="/var/vcap/all-releases/jobs-src/cf-smoke-tests/smoke_tests/templates/test.erb"

# Patch test.erb to add the correct cf-cli path to $PATH.
PATCH=$(cat <<'EOT'
8c8
< export PATH=/var/vcap/packages/cf-cli-6-linux/bin:${PATH} # put the cli on the path
---
> export PATH=/var/vcap/data/shared-packages/cf-cli-6-linux/bin:${PATH} # put the cli on the path
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi