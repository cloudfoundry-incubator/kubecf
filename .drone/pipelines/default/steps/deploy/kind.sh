#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"

bazel run //dev/kind:start

# ==================================================================================================
# Connect the kind container to the kubecf-drone-ci network.
# It allows the k8s cluster to use the image registry caches running on the same host Docker daemon.
docker network connect \
  kubecf-drone-ci \
  kubecf-control-plane

docker exec -i kubecf-control-plane \
  bash -c 'cat >> "/etc/containerd/config.toml"' <<EOT

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
  endpoint = ["http://kubecf-drone-ci-registry-dockerio:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.suse.com"]
  endpoint = ["http://kubecf-drone-ci-registry-registrysusecom:5000"]
EOT

docker exec -i kubecf-control-plane \
  bash -c 'service containerd restart'
