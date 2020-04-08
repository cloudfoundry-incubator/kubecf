#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools jq j2y y2j helm

if [[ ! "$(git submodule status -- src/cf-deployment)" =~ ^[[:space:]] ]]; then
    die "git submodule for cf-deployment is uninitialized or not up-to-date"
fi

HELM_DIR="${TEMP_DIR}/helm"

[ -d "${HELM_DIR}" ] && rm -rf "${HELM_DIR}"
mkdir "${HELM_DIR}"

cp -a deploy/helm/kubecf/{Chart,values}.yaml "${HELM_DIR}"
cp -a deploy/helm/kubecf/assets "${HELM_DIR}/assets"
cp -a deploy/helm/kubecf/templates "${HELM_DIR}/templates"

cp src/cf-deployment/cf-deployment.yml "${HELM_DIR}/assets"
cp src/cf-deployment/operations/bits-service/use-bits-service.yml "${HELM_DIR}/assets"

mkdir -p "${HELM_DIR}/assets/jobs"

function extract_job {
    y2j < src/cf-deployment/cf-deployment.yml |
        jq ".instance_groups[] | select(.name == \"$1\") | .jobs[] | select(.name == \"$2\")" |
        j2y > "${HELM_DIR}/assets/jobs/${2/-/_}_job.yaml"
}

extract_job scheduler auctioneer
extract_job api routing-api

mkdir -p "${HELM_DIR}/assets/operations/pre_render_scripts"

# shellcheck disable=SC2044
for PRE_RENDER_SCRIPT in $(find bosh/releases/pre_render_scripts -name '*.sh'); do
    FILE=$(basename "${PRE_RENDER_SCRIPT}")
    TYPE=$(basename "$(dirname "${PRE_RENDER_SCRIPT}")")
    JOB=$(basename "$(dirname "$(dirname "${PRE_RENDER_SCRIPT}")")")
    INSTANCE_GROUP=$(basename "$(dirname "$(dirname "$(dirname "${PRE_RENDER_SCRIPT}")")")")

    OUTPUT="${HELM_DIR}/assets/operations/pre_render_scripts/${INSTANCE_GROUP}_${JOB}_${FILE/\./_}.yaml"

    cat <<EOT > "${OUTPUT}"
- type: replace
  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties/quarks?/pre_render_scripts/${TYPE}/-
  value: |
EOT
    sed 's/^/    /' < "${PRE_RENDER_SCRIPT}" >> "${OUTPUT}"
done

echo "operatorChartUrl: \"${CF_OPERATOR_URL}\"" > "${HELM_DIR}/Metadata.yaml"

VERSION="v0.0.0-$(git rev-parse --short HEAD)"
helm package "${HELM_DIR}" --version "${VERSION}" --app-version "${VERSION}" --destination output/

rm -rf "${HELM_DIR}"
