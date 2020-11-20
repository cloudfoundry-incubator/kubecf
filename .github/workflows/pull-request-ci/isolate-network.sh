#!/usr/bin/env bash

# This script will add (or remove) a network policy to isolate traffic to a
# KubeCF deployment for CI purposes.

# Usage: ${0} <--enable|--disable>
# --enable turns on the isolation; --disable resets it.

set -o errexit -o nounset -o pipefail
: "${KUBECF_NAMESPACE:=kubecf}"

case "${1:-}" in
    --enable)
        true;;
    --disable)
        kubectl delete NetworkPolicies --namespace "${KUBECF_NAMESPACE}" \
            --ignore-not-found cats-internetless
        exit 0;;
    *)
        >&2 echo "Usage: ${0} < --enable | --disable>"
        exit 1;;
esac

# enable isolation
# ingress - allows all incoming traffic
# egress  - allows dns traffic anywhere
#         - allows traffic to all ports, pods, namespaces
#           (but no whitelisting of external ips!)
# references
# - BASE = https://github.com/ahmetb/kubernetes-network-policy-recipes
# - (BASE)/blob/master/02a-allow-all-traffic-to-an-application.md
# - (BASE)/blob/master/14-deny-external-egress-traffic.md
# - See also https://www.youtube.com/watch?v=3gGpMmYeEO8 (31min)
#   - Egress info wrt disallow external see 17:20-17:52
#
# __ATTENTION__
# Requires a networking plugin to enforce, else ignored
# (if not directly supported by platform)
# - Example plugins: Calico, WeaveNet, Romana
#
# GKE: Uses Calico, Use `--enable-network-policy` when
# creating a cluster (`gcloud`).
# Minikube needs special setup.
# KinD used by our Drone setup may have support.

kubectl apply -f - <<-EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cats-internetless
  namespace: ${KUBECF_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
    - ports:
      - port: 53
        protocol: UDP
      - port: 53
        protocol: TCP
    - to:
      - namespaceSelector: {}
EOF
