#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/pre-start.erb"

# Patch bin/pre-start.erb for the certificates to work with SUSE.
PATCH=$(cat <<'EOT'
24c24
< rm -f /usr/local/share/ca-certificates/uaa_*
---
> rm -f /etc/pki/trust/anchors/uaa_*
26,27c26,27
<     echo "Adding certificate from manifest to OS certs /usr/local/share/ca-certificates/uaa_<%= i %>.crt"
<     echo -n '<%= cert %>' >> "/usr/local/share/ca-certificates/uaa_<%= i %>.crt"
---
>     echo "Adding certificate from manifest to OS certs /etc/pki/trust/anchors/uaa_<%= i %>.crt"
>     echo -n '<%= cert %>' >> "/etc/pki/trust/anchors/uaa_<%= i %>.crt"
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi