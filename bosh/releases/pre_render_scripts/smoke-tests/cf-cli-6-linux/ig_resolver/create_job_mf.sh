#!/usr/bin/env bash

set -o errexit -o nounset

release="cf-cli"
job="cf-cli-6-linux"
job_mf="/var/vcap/all-releases/jobs-src/${release}/${job}/job.MF"
mkdir -p "$(dirname "${job_mf}")"
cat <<EOT > "${job_mf}"
---
name: ${job}

packages: []

templates:
  bin/pre-start: bin/pre-start

properties: {}
EOT
