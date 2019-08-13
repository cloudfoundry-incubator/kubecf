#!/usr/bin/env bash

set -o errexit -o nounset

{
cat <<EOT
- type: replace
  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties/quarks?/pre_render_scripts/${TYPE}/-
  value: |
EOT
sed 's/^/    /' < "${PRE_RENDER_SCRIPT}"
} > "${OUTPUT}"
