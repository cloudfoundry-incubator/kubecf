#!/usr/bin/env bash

# Add bin/pre-start to the buildpack job templates.

set -o errexit -o nounset

release="binary-buildpack"
job="binary-buildpack"

job_mf="/var/vcap/all-releases/jobs-src/${release}/${job}/job.MF"

sed -i 's|templates: {}||' "${job_mf}"
cat <<EOT > "${job_mf}"
templates:
  bin/pre-start: bin/pre-start
EOT
