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
    --image "kindest/node:${K8S_VERSION}"
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

# Make the node trust Kube's CA.
docker exec "${CLUSTER_NAME}-control-plane" bash -c "cp /etc/kubernetes/pki/ca.crt /usr/local/share/ca-certificates/kube-ca.crt;update-ca-certificates;service containerd restart"
