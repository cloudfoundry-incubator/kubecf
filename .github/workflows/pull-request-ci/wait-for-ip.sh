#!/usr/bin/env bash

# This script waits for services LB/Ingress-terminated (not with hardcoded IPs) to be accessible
# by the IP they expose

set -o errexit -o nounset

selector=(
      'app.kubernetes.io/component=router'
      '!quarks.cloudfoundry.org/instance-group-name'
    )
jsonpath='{.items[].status.loadBalancer.ingress[].ip}'
filter=(
      '--namespace=kubecf'
      '--selector='"$(IFS=, ; echo "${selector[*]}")"
    )
ip="$(kubectl get service "${filter[@]}" --output="jsonpath=${jsonpath}")"
system_domain="$(gomplate --context ".=${GITHUB_WORKSPACE}/kubecf-values.yaml" --in '{{ .system_domain }}')"

for host in api login; do
    fqdn="${host}.${system_domain}"
    printf "Waiting for %s to have IP address %s..." "${fqdn}" "${ip}"
    while [[ "$(dig +short "${fqdn}")" != "${ip}" ]]; do
        printf "."
        sleep 10
    done
    printf "Done.\n"
done
