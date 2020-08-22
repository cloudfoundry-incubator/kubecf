#!/bin/bash -ex

cd $(dirname $0)/..

helm package bits
helm repo index . --url https://cloudfoundry-incubator.github.io/bits-service-release/helm
helm repo add bits https://cloudfoundry-incubator.github.io/bits-service-release/helm
helm repo list
