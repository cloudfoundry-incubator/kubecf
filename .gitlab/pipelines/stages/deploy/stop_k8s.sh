#!/usr/bin/env bash

set -o errexit -o nounset

pgrep --full 'k3s server' | xargs --no-run-if-empty sudo kill
