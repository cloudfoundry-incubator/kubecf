#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/rep/templates/rep.json.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Don't share /var/vcap/packages between containers.
patch --verbose "${target}" <<'EOT'
@@ -1,4 +1,5 @@
 <%=
+  require 'socket'
   conf_dir = "/var/vcap/jobs/#{p("diego.rep.job_name")}/config"
   tmp_dir = "/var/vcap/data/rep/tmp"
   trusted_certs_dir = "/var/vcap/data/rep/shared/garden/trusted_certs"
@@ -28,7 +29,7 @@
     advertise_domain: p("diego.rep.advertise_domain"),
     auto_disk_capacity_overhead_mb: p("diego.executor.auto_disk_capacity_overhead_mb"),
     cache_path: "#{download_cache_dir}",
-    cell_id: spec.id,
+    cell_id: p('diego.rep.placement_tags').empty? ? spec.id : p('diego.rep.placement_tags').first + '-' + spec.id,
     cell_registrations_locket_enabled: p("cell_registrations.locket.enabled"),
     container_inode_limit: p("diego.executor.container_inode_limit"),
     container_max_cpu_shares: p("diego.executor.container_max_cpu_shares"),
@@ -39,7 +40,7 @@
     disk_mb: p("diego.executor.disk_capacity_mb").to_s,
     enable_consul_service_registration: p("enable_consul_service_registration"),
     enable_declarative_healthcheck: p("enable_declarative_healthcheck"),
-    declarative_healthcheck_path: "/var/vcap/packages/healthcheck",
+    declarative_healthcheck_path: "/var/vcap/data/shared-packages/healthcheck",
     enable_container_proxy: p("containers.proxy.enabled"),
     container_proxy_require_and_verify_client_certs: p("containers.proxy.require_and_verify_client_certificates"),
     container_proxy_trusted_ca_certs: p("containers.proxy.trusted_ca_certificates"),
@@ -48,7 +49,7 @@
     advertise_preference_for_instance_address: p("diego.rep.advertise_preference_for_instance_address"),
     enable_unproxied_port_mappings: p("containers.proxy.enable_unproxied_port_mappings"),
     proxy_memory_allocation_mb: p("containers.proxy.additional_memory_allocation_mb"),
-    container_proxy_path: "/var/vcap/packages/proxy",
+    container_proxy_path: "/var/vcap/data/shared-packages/proxy",
     container_proxy_config_path: "/var/vcap/data/rep/shared/garden/proxy_config",
     evacuation_polling_interval: "#{p("diego.rep.evacuation_polling_interval_in_seconds")}s",
     evacuation_timeout: "#{p("diego.rep.evacuation_timeout_in_seconds")}s",
EOT

sha256sum "${target}" > "${sentinel}"
