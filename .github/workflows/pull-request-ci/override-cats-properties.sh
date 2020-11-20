#!/usr/bin/env bash

# This script edits the CATS QuarksJob to have different properties set; this is
# used to be able to change the tests without redeploying the whole cluster.

# Usage: echo '{foo: bar}' | ${0}
# The input is YAML text for the properties to set / override; the `properties.`
# prefix is implied.

set -o errexit -o nounset -o pipefail

# The name of the namespace that KubeCF was deployed into.
: "${KUBECF_NAMESPACE:=kubecf}"

# The name of the new secret to create
: "${NEW_SECRET_NAME:=cats-overrides}"

# Find the name of the secret currently configured in the acceptance-tests QJob
# for the ig-resolved mount.
get_resolved_secret_name() {
    local jsonpath=(
        spec template spec template spec
        'volumes[?(@.name == "ig-resolved")]'
        secret secretName
    )
    kubectl get QuarksJob acceptance-tests \
        --namespace "${KUBECF_NAMESPACE}" \
        --output=jsonpath="{.$(IFS=. ; echo "${jsonpath[*]}")}"
}

# Create a copy of the ig-resolved secret that has updated properties set.
create_new_secret() {
    local overrides secret_name properties properties_yaml
    # Read the properties we want to read from stdin
    overrides="$(gomplate --context=.=stdin:///overrides.yaml \
        --in '{{ toJSON . }}')"
    # Get the existing secret to override
    secret_name="$(get_resolved_secret_name)"
    # Read the existing secret and convert to JSON
    properties="$(kubectl get secret --namespace="${KUBECF_NAMESPACE}" \
        "${secret_name}" --output=jsonpath='{.data.properties\.yaml}' \
        | base64 -d \
        | gomplate --context=.=stdin:///properties.yaml --in '{{ toJSON . }}')"
    # Update the properties in-place with the overrides
    properties="$(jq <<<"${properties}" '(
        .instance_groups[] | select(.name == "acceptance-tests") |
        .jobs[] | select(.name == "acceptance-tests") |
        .properties) *= ($ARGS.positional[0] // {})' \
        --jsonargs "${overrides}")"
    # Convert the properties from JSON to YAML
    properties_yaml="$(<<<"${properties}" \
        gomplate --context=.=stdin:///f.json --in='{{ toYAML . }}')"
    # Create (or update) the secret with the overrides set
    kubectl create secret generic --namespace="${KUBECF_NAMESPACE}" \
        "${NEW_SECRET_NAME}" --from-file=properties.yaml=/dev/stdin \
        --dry-run=client --output=yaml <<<"${properties_yaml}" \
        | kubectl apply -f -
}

# Update the acceptance-tests QuarksJob to use the new secret
mount_new_secret() {
    # QJob's spec...volumes doesn't support JSON merge, so we need to fetch the
    # existing volumes and update it instead.

    # Get the original set of volumes
    local original_volumes
    original_volumes="$(kubectl get QuarksJob acceptance-tests \
        --namespace="${KUBECF_NAMESPACE}" \
        --output=json | jq -r '.spec.template.spec.template.spec.volumes')"

    # Mutate it to mount the new secret for ig-resolved
    local updated_volumes
    updated_volumes="$(<<<"${original_volumes}" \
        jq -r "map((select(.name==\"ig-resolved\") | .secret.secretName) |=
            \"${NEW_SECRET_NAME}\")")"

    # Generate a JSON merge struct with our change
    local patch
    patch="$(jq -r <<<'{}' \
        ".spec.template.spec.template.spec.volumes |= ${updated_volumes}")"

    # Actually patch it
    kubectl patch QuarksJob acceptance-tests --namespace "${KUBECF_NAMESPACE}" \
        --type merge --patch "${patch}"
}

create_new_secret
mount_new_secret
