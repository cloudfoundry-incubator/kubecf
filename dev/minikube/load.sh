#!/usr/bin/env bash

set -o errexit -o nounset

# call the executable to make sure it works, because the eval() later doesn't
# actually guarantee that it does
"${MINIKUBE}" status >/dev/null

# shellcheck disable=SC2046
eval $("${MINIKUBE}" docker-env)

if [[ "${#DOCKER_IMAGES[@]}" -gt 0 ]] ; then
  docker load --input "${DOCKER_IMAGES[@]}"
fi
