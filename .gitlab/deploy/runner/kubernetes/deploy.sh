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
  --wait \
  --namespace "${namespace}" \
  --values .gitlab/deploy/runner/kubernetes/values.yaml \
  --set "runners.namespace=${namespace}" \
  --set "runnerRegistrationToken=${runner_registration_token}"

# shellcheck disable=SC1004,SC2016
kubectl patch "configmap/${installation_name}-gitlab-runner" \
  --namespace "${namespace}" \
  --patch '
"data":
  "entrypoint": |
    #!/bin/bash
    set -e
    mkdir -p /home/gitlab-runner/.gitlab-runner/
    cp /scripts/config.toml /home/gitlab-runner/.gitlab-runner/

    # Register the runner
    if [[ -f /secrets/accesskey && -f /secrets/secretkey ]]; then
      export CACHE_S3_ACCESS_KEY=$(cat /secrets/accesskey)
      export CACHE_S3_SECRET_KEY=$(cat /secrets/secretkey)
    fi

    if [[ -f /secrets/gcs-applicaton-credentials-file ]]; then
      export GOOGLE_APPLICATION_CREDENTIALS="/secrets/gcs-applicaton-credentials-file"
    else
      if [[ -f /secrets/gcs-access-id && -f /secrets/gcs-private-key ]]; then
        export CACHE_GCS_ACCESS_ID=$(cat /secrets/gcs-access-id)
        # echo -e used to make private key multiline (in google json auth key private key is oneline with \n)
        export CACHE_GCS_PRIVATE_KEY=$(echo -e $(cat /secrets/gcs-private-key))
      fi
    fi

    if [[ -f /secrets/runner-registration-token ]]; then
      export REGISTRATION_TOKEN=$(cat /secrets/runner-registration-token)
    fi

    if [[ -f /secrets/runner-token ]]; then
      export CI_SERVER_TOKEN=$(cat /secrets/runner-token)
    fi

    if ! sh /scripts/register-the-runner; then
      exit 1
    fi

    # Add docker volumes
    cat >> /home/gitlab-runner/.gitlab-runner/config.toml << EOF
        [[runners.kubernetes.volumes.empty_dir]]
          name = "k3s"
          mount_path = "/var/lib/rancher/k3s"
    EOF

    # Start the runner
    exec /entrypoint run --user=gitlab-runner \
      --working-directory=/home/gitlab-runner
'

kubectl get pods --namespace "${namespace}" --output name | grep "gitlab-runner" | xargs --no-run-if-empty kubectl delete --namespace "${namespace}"
