#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/eirini/opi/templates/bpm.yml.erb"

# Patch BPM, since we're actually running in-cluster without BPM
PATCH=$(cat <<'EOT'
@@ -4,17 +4,3 @@
     args:
     - connect
     - --config=/var/vcap/jobs/opi/config/opi.yml
-    env:
-      KUBERNETES_SERVICE_HOST: "<%= p("opi.kube_service_host") %>"
-      KUBERNETES_SERVICE_PORT: "<%= p("opi.kube_service_port") %>"
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
  echo "Patch already applied. Skipping"
fi
