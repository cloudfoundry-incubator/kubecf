#!/usr/bin/env bash

set -o errexit -o nounset

touch "${OUTPUT}"

{
  echo "- type: replace";
  echo "  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties/bosh_containerization?/pre_render_scripts/-";
  echo "  value: |";
  sed 's/^/    /' < "${PRE_RENDER_SCRIPT}";
} >> "${OUTPUT}"
