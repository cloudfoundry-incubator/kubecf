#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/eirini/eirini-persi/templates/bpm.yml.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  echo "Patch already applied. Skipping"
  exit 0
fi

# Patch BPM, since we're actually running in-cluster without BPM
patch --verbose "${target}" <<'EOT'
@@ -3,21 +3,8 @@ processes:
     executable: /var/vcap/packages/eirini-persi/bin/eirini-persi
     args: []
     env:
-      KUBERNETES_SERVICE_HOST: "<%= p("eirini-persi.kube_service_host") %>"
-      KUBERNETES_SERVICE_PORT: "<%= p("eirini-persi.kube_service_port") %>"
       OPERATOR_WEBHOOK_HOST: "<%= p("eirini-persi.operator_webhook_host") %>"
       OPERATOR_WEBHOOK_PORT: "<%= p("eirini-persi.operator_webhook_port") %>"
       NAMESPACE: "<%= p("eirini-persi.namespace") %>"
       OPERATOR_SERVICE_NAME: "<%= p("eirini-persi.operator_webhook_servicename") %>"
       OPERATOR_WEBHOOK_NAMESPACE: "<%= p("eirini-persi.operator_webhook_namespace") %>"
-    <% if properties.opi&.k8s&.host_url.nil? %>
-    # The ServiceAccount admission controller has to be enabled.
-    # https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod
-    additional_volumes:
-    - path: /var/run/secrets/kubernetes.io/serviceaccount/token
-      mount_only: true
-    - path: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
-      mount_only: true
-    - path: /var/run/secrets/kubernetes.io/serviceaccount/namespace
-      mount_only: true
-    <% end %>
EOT

touch "${sentinel}"
