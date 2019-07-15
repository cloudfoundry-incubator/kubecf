#!/usr/bin/env bash

set -o errexit -o nounset

touch "${OUTPUT}"

function append {
  echo "${1}" >> "${OUTPUT}"
}

append "- type: replace"
append "  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties/bosh_containerization?/pre_render_scripts/-"
append "  value: |"
append "$(cat "${PRE_RENDER_SCRIPT}" | sed 's/^/    /')"
