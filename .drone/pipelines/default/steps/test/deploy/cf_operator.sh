#!/usr/bin/env bash

set -o errexit -o nounset

kubectl create namespace "${CF_OPERATOR_NAMESPACE}"
bazel run //dev/cf_operator:apply
