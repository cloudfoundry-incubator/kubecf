#!/usr/bin/env bash

# Create the pre-start script that copies the cf-cli packages to /var/vcap/data/shared-packages/.

set -o errexit -o nounset

release="cf-cli"
job="cf-cli-6-linux"
pre_start="/var/vcap/all-releases/jobs-src/${release}/${job}/templates/bin/pre-start"
copy_dst_dir="/var/vcap/data/shared-packages/"
mkdir -p "$(dirname "${pre_start}")"
cat <<EOT > "${pre_start}"
#!/usr/bin/env bash
set -o errexit
mkdir -p "${copy_dst_dir}"
cp -r /var/vcap/packages/* "${copy_dst_dir}"
EOT
