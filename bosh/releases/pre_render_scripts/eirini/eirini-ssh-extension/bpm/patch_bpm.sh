#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/eirini/eirini-ssh-extension/templates/bpm.yml.erb"

# Patch BPM, since we're actually running in-cluster without BPM
PATCH=$(cat <<'EOT'
@@ -3,21 +3,8 @@ processes:
     executable: /var/vcap/packages/eirini-ssh-extension/bin/eirini-ssh-extension
     args: []
     env:
-      KUBERNETES_SERVICE_HOST: "<%= p("eirini-ssh-extension.kube_service_host") %>"
-      KUBERNETES_SERVICE_PORT: "<%= p("eirini-ssh-extension.kube_service_port") %>"
       EIRINI_EXTENSION_HOST: "<%= p("eirini-ssh-extension.operator_webhook_host") %>"
       EIRINI_EXTENSION_PORT: "<%= p("eirini-ssh-extension.operator_webhook_port") %>"
       EIRINI_EXTENSION_NAMESPACE: "<%= p("eirini-ssh-extension.namespace") %>"
       OPERATOR_SERVICE_NAME: "<%= p("eirini-ssh-extension.operator_webhook_servicename") %>"
       OPERATOR_WEBHOOK_NAMESPACE: "<%= p("eirini-ssh-extension.operator_webhook_namespace") %>"
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
)

# Only patch once
if ! patch --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. skipping"
fi
