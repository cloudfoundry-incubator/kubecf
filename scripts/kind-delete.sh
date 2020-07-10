#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kind

kind delete cluster --name "${CLUSTER_NAME}"
