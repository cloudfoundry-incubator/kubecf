#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

target="/var/vcap/all-releases/jobs-src/silk/silk-cni/templates/cni-wrapper-plugin.conflist.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Resolve DNS Servers passed via the `dns_servers` property if any is a hostname
# instead of an IP address.
patch --verbose "${target}" <<'EOT'
@@ -2,6 +2,7 @@
 <%=
   require 'ipaddr'
   require 'json'
+  require 'resolv'
 
   def compute_mtu
     vxlan_overhead = 50
@@ -41,6 +42,14 @@
     end
   end
 
+  dns_servers = p('dns_servers').map do |dns_server|
+    if !(dns_server =~ Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]))
+      Resolv.getaddress dns_server
+    else
+      dns_server
+    end
+  end
+
   toRender = {
     'name' => 'cni-wrapper',
     'cniVersion' => '0.3.1',
@@ -61,7 +70,7 @@
       'ingress_tag' => 'ffff0000',
       'vtep_name' => 'silk-vtep',
       'policy_agent_force_poll_address' => '127.0.0.1:' + link('vpa').p('force_policy_poll_cycle_port').to_s,
-      'dns_servers' => p('dns_servers'),
+      'dns_servers' => dns_servers,
       'host_tcp_services' => p('host_tcp_services'),
       'host_udp_services' => p('host_udp_services'),
       'deny_networks' => {
EOT

sha256sum "${target}" > "${sentinel}"
