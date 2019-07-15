#!/usr/bin/env bash

set -o errexit

# Patch bin/pre-start.erb for the certificates to work with SUSE.
patch /var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/pre-start.erb <<'EOT'
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

# Patch bin/uaa.erb for the certificates to work with SUSE.
patch /var/vcap/all-releases/jobs-src/uaa/uaa/templates/bin/uaa.erb <<'EOT'
49c49
< cp /etc/ssl/certs/ca-certificates.crt "$CERT_FILE"
---
> cp /var/lib/ca-certificates/ca-bundle.pem "$CERT_FILE"
EOT
