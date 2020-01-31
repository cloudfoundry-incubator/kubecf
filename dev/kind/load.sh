#!/usr/bin/env bash

set -o errexit -o nounset

"${KIND}" load image-archive --name "${CLUSTER_NAME}" "${DOCKER_IMAGES[@]}"
