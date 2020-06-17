#!/usr/bin/env bash

set -o errexit -o nounset

function cluster_exists {
  "${KIND}" get clusters | awk "/^${CLUSTER_NAME}\$/{ rc = 1 }; END { exit !rc }"
  return $?
}

# Create the cluster.
if ! cluster_exists; then
  "${KIND}" create cluster \
    --name "${CLUSTER_NAME}" \
    --image "kindest/node:${K8S_VERSION}" \
    --config "${KIND_CONFIG}"

  # Make the node trust Kube's CA.
  docker exec "${CLUSTER_NAME}-control-plane" bash -c "cp /etc/kubernetes/pki/ca.crt /usr/local/share/ca-certificates/kube-ca.crt;update-ca-certificates;service containerd restart"

  # This is the default CoreDNS config with the 'forward' plugin pointing to 1.1.1.1 instead of
  # /etc/resolv.conf. This allows a more deterministic DNS behaviour when connecting the kind
  # container to a different network. With Docker, /etc/resolv.conf gets rewritten with Docker's
  # nameserver (127.0.0.11).
  "${KUBECTL}" apply -f - <<'EOT'
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
      errors
      health
      ready
      kubernetes cluster.local in-addr.arpa ip6.arpa {
         pods insecure
         upstream
         fallthrough in-addr.arpa ip6.arpa
         ttl 30
      }
      prometheus :9153
      forward . 1.1.1.1
      cache 30
      loop
      reload
      loadbalance
    }
EOT

  # Install the Weave container network plugin.
  "${KUBECTL}" apply -f "${WEAVE_CONTAINER_NETWORK_PLUGIN}"
else
  echo "Kind is already started"
fi

# Create a storage class.
"${KUBECTL}" apply --filename "${LOCAL_PATH_STORAGE_YAML}"
"${KUBECTL}" patch storageclass standard \
  --patch '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false", "storageclass.beta.kubernetes.io/is-default-class":"false"}}}'
"${KUBECTL}" patch storageclass local-path \
  --patch '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true", "storageclass.beta.kubernetes.io/is-default-class":"true"}}}'

# Deploy the kube dashboard.
"${KUBECTL}" apply -f "${KUBE_DASHBOARD_YAML}"

# Create the metrics server.
"${KUBECTL}" apply -f "${METRICS_SERVER}"
