#!/usr/bin/env bash

set -o errexit -o nounset

default_installation_name="gitlab-runner"
printf "Installation name (%s): " "${default_installation_name}"
read -r installation_name
if [ -z "${installation_name}" ]; then
  installation_name="${default_installation_name}"
fi

default_namespace="gitlab-runner"
printf "Namespace (%s): " "${default_namespace}"
read -r namespace
if [ -z "${namespace}" ]; then
  namespace="${default_namespace}"
fi

default_personal_id="$(whoami)"
printf "Personal ID (%s): " "${default_personal_id}"
read -r personal_id
if [ -z "${personal_id}" ]; then
  personal_id="${default_personal_id}"
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

helm upgrade "${installation_name}" gitlab/gitlab-runner \
  --install \
  --namespace "${namespace}" \
  --values .gitlab/deploy/runner/kubernetes/values.yaml \
  --set "runners.namespace=${namespace}" \
  --set "runnerRegistrationToken=${runner_registration_token}"
