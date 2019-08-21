#!/usr/bin/env bash

# Create the pre-start script that copies the buildpack package to /var/vcap/data/shared-packages/.

set -o errexit -o nounset

release="php-buildpack"
buildpack="php-buildpack"

pre_start="/var/vcap/all-releases/jobs-src/${release}/${buildpack}/templates/bin/pre-start"
copy_dst="/var/vcap/data/shared-packages/${buildpack}/"
mkdir -p "$(dirname "${pre_start}")"
cat <<EOT > "${pre_start}"
#!/usr/bin/env bash
set -o errexit
mkdir -p "${copy_dst}"
cp -r /var/vcap/packages "${copy_dst}"
EOT
