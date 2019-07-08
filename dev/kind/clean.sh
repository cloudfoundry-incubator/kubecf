#!/usr/bin/env bash

set -o nounset

kind delete cluster --name scf
docker rm -f scf-control-plane
