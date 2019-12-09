#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/eirini/eirini-ssh-proxy/templates/bpm.yml.erb"

# Patch BPM, since we're actually running in-cluster without BPM
PATCH=$(cat <<'EOT'
@@ -5,18 +5,5 @@ processes:
       - "--config"
       - "/var/vcap/jobs/eirini-ssh-proxy/config/eirini-ssh-proxy.json"
     env:
-      KUBERNETES_SERVICE_HOST: "<%= p("eirini-ssh-proxy.kube_service_host") %>"
-      KUBERNETES_SERVICE_PORT: "<%= p("eirini-ssh-proxy.kube_service_port") %>"
       SSH_PROXY_KUBERNETES_NAMESPACE: "<%= p("eirini-ssh-proxy.kube_namespace") %>"
       SSH_PROXY_DAEMON_PORT: "<%= p("eirini-ssh-proxy.sshd_port") %>"
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
