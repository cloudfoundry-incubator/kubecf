#!/usr/bin/env bash

target="/var/vcap/all-releases/jobs-src/cf-smoke-tests/smoke_tests/templates/test.erb"

# Patch test.erb to add the correct cf-cli path to $PATH.
patch --verbose "${target}" <<'EOT'
8c8
< export PATH=/var/vcap/packages/cf-cli-6-linux/bin:${PATH} # put the cli on the path
---
> export PATH=/var/vcap/data/shared-packages/cf-cli-6-linux/bin:${PATH} # put the cli on the path
EOT
