#!/usr/bin/env bash

set -o errexit -o nounset

default_installation_name="gitlab-ci-runner"
printf "Installation name (%s): " "${default_installation_name}"
read -r installation_name
if [ -z "${installation_name}" ]; then
  installation_name="${default_installation_name}"
fi

default_namespace="gitlab"
printf "Namespace (%s): " "${default_namespace}"
read -r namespace
if [ -z "${namespace}" ]; then
  namespace="${default_namespace}"
fi

stty -echo
printf "Runner registration token: "
read -r runner_registration_token
stty echo
printf "\\n"
if [ -z "${runner_registration_token}" ]; then
  >&2 echo "The runner registration token cannot be empty"
  exit 1
fi

workspace="$(bazel info workspace)"

kubectl create namespace "${namespace}" 2> /dev/null || true

kubectl apply --namespace "${namespace}" -f "${workspace}/.gitlab/deploy/runner/kubernetes/ephemeral_volume_k3s.yaml"

helm upgrade "${installation_name}" gitlab/gitlab-runner \
  --install \
  --wait \
  --namespace "${namespace}" \
  --values "${workspace}/.gitlab/deploy/runner/kubernetes/values.yaml" \
  --set "runners.namespace=${namespace}" \
  --set "runnerRegistrationToken=${runner_registration_token}"
