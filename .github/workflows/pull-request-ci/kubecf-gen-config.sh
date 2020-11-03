#!/usr/bin/env bash

# This is called in the `Generate KubeCF Configuration` step of `pull-request-ci.yaml`

set -o errexit -o nounset -o pipefail

make -C "${GITHUB_WORKSPACE}/catapult" kubecf-gen-config

cd "${GITHUB_WORKSPACE}"
cp "${GITHUB_WORKSPACE}/catapult/build${CLUSTER_NAME:-${BACKEND}}/scf-config-values.yaml" \
   kubecf-values.yaml

# Usage: merge < (YAML data)
function merge() {
    gomplate --datasource 'merged=merge:additional|original' \
        --datasource original=kubecf-values.yaml \
        --datasource additional=stdin:///additional.yaml \
        --in '{{ datasource "merged" | toYAML }}' \
        --out kubecf-values-merged.yaml
    mv kubecf-values-merged.yaml kubecf-values.yaml
}

# Run ginkgo in parallel for faster tests
merge <<< '
        properties:
            acceptance-tests:
                acceptance-tests:
                    acceptance_tests:
                        ginkgo:
                            nodes: 3
    '

# Set Eirini overrides
if [ "${ENABLE_EIRINI}" == "true" ]; then
    # This is what upstream Eirini was running and was green:
    # https://github.com/cloudfoundry-incubator/eirini-ci/blob/09dcce6d9e900f693dfc1a6da70b5a526cf7de18/pipelines/dhall-modules/jobs/run-core-cats.dhall#L52-L86

    # Normally, it only makes sense to disable test groups that are enabled by
    # default and enable those that aren't:
    # https://github.com/cloudfoundry/cf-acceptance-tests#test-configuration
    # Below we keep the full (explicit) list though, to make it easier to switch
    # groups on and off.
    suites=(
        apps
        capi_no_bridge
        container_networking
        detect
        docker
        internet_dependent
        routing
        sso
        v3
        zipkin
        ssh
    )
    merge <<<"
        properties:
            acceptance-tests:
                acceptance-tests:
                    acceptance_tests:
                        include: '$(IFS=, ; echo "=${suites[*]}")'
                        stacks: [ sle15 ]
                        credhub_mode: skip-tests
    "
fi

echo "::group::kubecf-config-values.yaml"
cat "${GITHUB_WORKSPACE}/kubecf-values.yaml"
echo "::endgroup::"
