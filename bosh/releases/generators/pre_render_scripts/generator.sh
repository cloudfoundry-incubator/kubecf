#!/usr/bin/env bash

set -o errexit -o nounset

{
cat <<EOT
- type: replace
  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties/bosh_containerization?/pre_render_scripts/-
  value: |
EOT
sed 's/^/    /' < "${PRE_RENDER_SCRIPT}"
} > "${OUTPUT}"
