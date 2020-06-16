#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/eirini/opi/templates/bpm.yml.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Patch BPM, since we're actually running in-cluster without BPM
patch --verbose "${target}" <<'EOT'
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

sha256sum "${target}" > "${sentinel}"
