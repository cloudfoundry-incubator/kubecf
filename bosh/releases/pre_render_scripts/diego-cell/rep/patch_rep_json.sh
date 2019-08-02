#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/rep/templates/rep.json.erb"

# Don't share /var/vcap/packages between containers.
patch --verbose "${target}" <<'EOT'
@@ -39,7 +39,7 @@
     disk_mb: p("diego.executor.disk_capacity_mb").to_s,
     enable_consul_service_registration: p("enable_consul_service_registration"),
     enable_declarative_healthcheck: p("enable_declarative_healthcheck"),
-    declarative_healthcheck_path: "/var/vcap/packages/healthcheck",
+    declarative_healthcheck_path: "/var/vcap/data/shared-packages/healthcheck",
     enable_container_proxy: p("containers.proxy.enabled"),
     container_proxy_require_and_verify_client_certs: p("containers.proxy.require_and_verify_client_certificates"),
     container_proxy_trusted_ca_certs: p("containers.proxy.trusted_ca_certificates"),
@@ -47,7 +47,7 @@
     container_proxy_ads_addresses: p("containers.proxy.ads_addresses"),
     enable_unproxied_port_mappings: p("containers.proxy.enable_unproxied_port_mappings"),
     proxy_memory_allocation_mb: p("containers.proxy.additional_memory_allocation_mb"),
-    container_proxy_path: "/var/vcap/packages/proxy",
+    container_proxy_path: "/var/vcap/data/shared-packages/proxy",
     container_proxy_config_path: "/var/vcap/data/rep/shared/garden/proxy_config",
     evacuation_polling_interval: "#{p("diego.rep.evacuation_polling_interval_in_seconds")}s",
     evacuation_timeout: "#{p("diego.rep.evacuation_timeout_in_seconds")}s",
EOT
