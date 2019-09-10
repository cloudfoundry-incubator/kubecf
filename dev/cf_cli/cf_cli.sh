#!/bin/bash

set -o errexit -o nounset

namespace="scf"
deployment_name="scf"
pod_name="cf-terminal"
api_ip=""
echo "Waiting for endpoint..."
while true; do
  api_ip=$(kubectl describe endpoints -n "${namespace}" "${deployment_name}-router" | awk 'match($0, /  Addresses:[ ]+(.*)/, ip) { print ip[1] }')
  if [ -n "${api_ip}" ]; then break; fi
  sleep 3
done
admin_password=$(kubectl get secret --namespace "${namespace}" "${deployment_name}.var-cf-admin-password" -o jsonpath='{.data.password}' | base64 --decode)
system_domain=$(kubectl get secret --namespace "${namespace}" "${deployment_name}.var-system-domain" -o jsonpath='{.data.value}' | base64 --decode)

kubectl delete pod --namespace "${namespace}" "${pod_name}" || true
kubectl create --namespace "${namespace}" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: "${pod_name}"
spec:
  hostAliases:
  - ip: "${api_ip}"
    hostnames:
    - "app1.${system_domain}"
    - "app2.${system_domain}"
    - "app3.${system_domain}"
    - "login.${system_domain}"
    - "api.${system_domain}"
    - "uaa.${system_domain}"
    - "doppler.${system_domain}"
  containers:
  - name: cf-terminal
    image: governmentpaas/cf-cli
    command: ["bash", "-c"]
    args:
    - |-
      set -o errexit
      cf api --skip-ssl-validation "api.${system_domain}"
      cf login -u admin -p "${admin_password}"
      cf create-org demo
      cf target -o demo
      cf create-space demo
      cf target -s demo
      cf enable-feature-flag diego_docker
      sleep 3600000
EOF
