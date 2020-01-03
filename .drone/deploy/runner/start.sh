#!/usr/bin/env bash

set -o errexit -o nounset

default_runner_name="$(hostname)"
printf "Runner name (%s): " "${default_runner_name}"
read -r runner_name
if [ -z "${runner_name}" ]; then
  runner_name="${default_runner_name}"
fi

stty -echo
printf "RPC secret: "
read -r rpc_secret
stty echo
printf "\\n"
if [ -z "${rpc_secret}" ]; then
  >&2 echo "The RPC secret cannot be empty"
  exit 1
fi

docker run \
  --name "kubecf-drone-ci-runner" \
  --detach \
  --privileged \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --env "DRONE_RUNNER_NAME=${runner_name}" \
  --env "DRONE_RPC_SECRET=${rpc_secret}" \
  --env "DRONE_RPC_HOST={rpc_host}" \
  --env "DRONE_RPC_PROTO={rpc_proto}" \
  --env "DRONE_RUNNER_CAPACITY={runner_capacity}" \
  --restart always \
  "drone/drone-runner-docker:{runner_image_version}@sha256:{runner_image_sha256}"

# ==================================================================================================
# Start the image registry caches.
docker run \
  --name kubecf-drone-ci-registry-dockerio \
  --detach \
  --volume /tmp/drone/docker/var/lib/registry:/var/lib/registry \
  --env "REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io" \
  --restart always \
  registry:2

docker run \
  --name kubecf-drone-ci-registry-registrysusecom \
  --detach \
  --volume /tmp/drone/docker/var/lib/registry:/var/lib/registry \
  --env "REGISTRY_PROXY_REMOTEURL=https://registry.suse.com" \
  --restart always \
  registry:2

# ==================================================================================================
# Connect the image registry caches to the kubecf-drone-ci network.
docker network create "{network_name}"
docker network connect "{network_name}" kubecf-drone-ci-registry-dockerio
docker network connect "{network_name}" kubecf-drone-ci-registry-registrysusecom
