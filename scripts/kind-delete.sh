#!/usr/bin/env bash

set -o nounset

"${KIND}" delete cluster --name "${CLUSTER_NAME}"
