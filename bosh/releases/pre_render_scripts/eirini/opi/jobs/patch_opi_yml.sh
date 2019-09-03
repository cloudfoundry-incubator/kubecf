#!/usr/bin/env bash
set -o errexit -o nounset

# Use kube-native service IPs for the CC Uploader and the
# Eirini registry
target="/var/vcap/all-releases/jobs-src/eirini/opi/templates/opi.yml.erb"

patch --verbose "${target}" <<'EOT'
10c10
<   cc_uploader_ip: <%= p("opi.cc_uploader_ip") %>
---
>   cc_uploader_ip: <%= ENV["{{ .Values.deployment_name | upper }}_CC_UPLOADER_SERVICE_HOST"] %>
12c12
<   registry_address: <%= p("opi.registry_address") %>
---
>   registry_address: <%= ENV["{{ .Values.deployment_name | upper }}_EIRINI_REGISTRY_SERVICE_HOST"] %>
EOT
