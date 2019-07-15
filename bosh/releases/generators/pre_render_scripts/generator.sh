#!/usr/bin/env bash

set -o errexit -o nounset

touch "${OUTPUT}"

echo "- type: replace" >> "${OUTPUT}"
echo "  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties/bosh_containerization?/pre_render_scripts/-" >> "${OUTPUT}"
echo "  value: |" >> "${OUTPUT}"
cat "${PRE_RENDER_SCRIPT}" | sed 's/^/    /' >> "${OUTPUT}"
