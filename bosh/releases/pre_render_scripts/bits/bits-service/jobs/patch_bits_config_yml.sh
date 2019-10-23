#!/usr/bin/env bash
set -o errexit -o nounset

# Use kube-native service IPs for the Eirini registry
target="/var/vcap/all-releases/jobs-src/bits-service/bits-service/templates/bits_config.yml.erb"

PATCH=$(cat <<'EOT'
409c409
< registry_endpoint: <%= registry %>
---
> registry_endpoint: https://<%= ENV["{{ .Values.deployment_name | upper }}_EIRINI_REGISTRY_SERVICE_HOST"] %>
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
