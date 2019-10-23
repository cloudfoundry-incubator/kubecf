#!/usr/bin/env bash
set -o errexit -o nounset

# Use kube-native service IPs for the CC Uploader and the
# Eirini registry
target="/var/vcap/all-releases/jobs-src/eirini/opi/templates/opi.yml.erb"

PATCH=$(cat <<'EOT'
10c10
<   cc_uploader_ip: <%= p("opi.cc_uploader_ip") %>
---
>   cc_uploader_ip: <%= ENV["{{ .Values.deployment_name | upper }}_CC_UPLOADER_SERVICE_HOST"] %>
12c12
<   registry_address: <%= p("opi.registry_address") %>
---
>   registry_address: <%= ENV["{{ .Values.deployment_name | upper }}_EIRINI_REGISTRY_SERVICE_HOST"] %>
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
