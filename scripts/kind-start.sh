#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kind kubectl

: "${KUBE_DASHBOARD_URL:=https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml}"
: "${LOCAL_PATH_PROVISIONER_URL:=https://raw.githubusercontent.com/rancher/local-path-provisioner/58cafaccef6645e135664053545ff94cb4bc4224/deploy/local-path-storage.yaml}"
: "${METRICS_SERVER_URL:=https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml}"
: "${WEAVE_DAEMONSET_URL:=https://github.com/weaveworks/weave/releases/download/v2.6.0/weave-daemonset-k8s-1.11.yaml}"


function cluster_exists {
  kind get clusters | awk "/^${CLUSTER_NAME}\$/{ rc = 1 }; END { exit !rc }"
  return $?
}

# Create the cluster.
if ! cluster_exists; then
  kind create cluster \
    --name "${CLUSTER_NAME}" \
    --image "kindest/node:v${K8S_VERSION}" \
    --loglevel debug \
    --config - <<'EOT'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
EOT

  # Make the node trust Kube's CA.
  docker exec "${CLUSTER_NAME}-control-plane" bash -c "cp /etc/kubernetes/pki/ca.crt /usr/local/share/ca-certificates/kube-ca.crt;update-ca-certificates;service containerd restart"

  # This is the default CoreDNS config with the 'forward' plugin pointing to 1.1.1.1 instead of
  # /etc/resolv.conf. This allows a more deterministic DNS behaviour when connecting the kind
  # container to a different network. With Docker, /etc/resolv.conf gets rewritten with Docker's
  # nameserver (127.0.0.11).
  kubectl apply -f - <<'EOT'
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
  kubectl apply -f "${WEAVE_DAEMONSET_URL}"
else
  echo "Kind is already started"
fi

# Create a storage class.
kubectl apply --filename "${LOCAL_PATH_PROVISIONER_URL}"
kubectl patch storageclass standard \
  --patch '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false", "storageclass.beta.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass local-path \
  --patch '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true", "storageclass.beta.kubernetes.io/is-default-class":"true"}}}'

# Deploy the kube dashboard.
kubectl apply -f "${KUBE_DASHBOARD_URL}"

# Create the metrics server.
kubectl apply -f "${METRICS_SERVER_URL}"

# https://github.com/kubernetes-sigs/metrics-server/issues/131#issuecomment-618671827
PATCH=$(cat <<'EOF'
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "metrics-server",
            "args": [
              "--v=2",
              "--cert-dir=/tmp",
              "--secure-port=4443",
              "--kubelet-insecure-tls",
              "--kubelet-preferred-address-types=InternalIP"
            ]
          }
        ]
      }
    }
  }
}
EOF
     )
kubectl patch deployment metrics-server -n kube-system -p "${PATCH}"
