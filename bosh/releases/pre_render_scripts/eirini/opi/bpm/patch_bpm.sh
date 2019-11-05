#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/eirini/opi/templates/bpm.yml.erb"

# Patch BPM, since we're actually running in-cluster without BPM
PATCH=$(cat <<'EOT'
@@ -5,9 +5,11 @@
     - connect
     - --config=/var/vcap/jobs/opi/config/opi.yml
     env:
-      KUBERNETES_SERVICE_HOST: "<%= p("opi.kube_service_host") %>"
-      KUBERNETES_SERVICE_PORT: "<%= p("opi.kube_service_port") %>"
-    <% if properties.opi&.k8s&.host_url.nil? %>
+      <% host = p("opi.kube_service_host") %>
+      <%= "KUBERNETES_SERVICE_HOST: \"#{host}\"" unless host.empty? %>
+      <% port = p("opi.kube_service_port") %>
+      <%= "KUBERNETES_SERVICE_PORT: \"#{port}\"" unless port.empty? %>
+    <% unless p("opi.k8s.host_url", "").empty? %>
     # The ServiceAccount admission controller has to be enabled.
     # https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod
     additional_volumes:
EOT
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
