#!/usr/bin/env bash
set -o errexit -o nounset

# Use kube-native service IPs for the Eirini registry
target="/var/vcap/all-releases/jobs-src/bits-service/bits-service/templates/bits_config.yml.erb"

patch --verbose "${target}" <<'EOT'
409c409
< registry_endpoint: <%= registry %>
---
> registry_endpoint: https://<%= ENV["{{ .Values.deployment_name | upper }}_EIRINI_REGISTRY_SERVICE_HOST"] %>
EOT
