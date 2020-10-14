#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools bosh cf_operator_url git helm jq ruby y2j

if [[ ! "$(git submodule status -- src/cf-deployment)" =~ ^[[:space:]] ]]; then
    die "git submodule for cf-deployment is uninitialized or not up-to-date"
fi

HELM_DIR="${TEMP_DIR}/helm"

[ -d "${HELM_DIR}" ] && rm -rf "${HELM_DIR}"
mkdir "${HELM_DIR}"

cp -a chart/* "${HELM_DIR}"
find "${HELM_DIR}" \( -name "*.bazel" -o -name "*.bzl" -o -name ".*" \) -delete

y2j < "${HELM_DIR}/values.schema.yaml" > "${HELM_DIR}/values.schema.json"
rm "${HELM_DIR}/values.schema.yaml"

cp src/cf-deployment/cf-deployment.yml "${HELM_DIR}/assets"
cp src/cf-deployment/operations/use-external-blobstore.yml "${HELM_DIR}/assets"
cp src/cf-deployment/operations/use-s3-blobstore.yml "${HELM_DIR}/assets"

for MIXIN in bits eirini eirinix; do
    for DIR in assets config templates; do
        if [ -d "mixins/${MIXIN}/${DIR}" ]; then
            cp -a "mixins/${MIXIN}/${DIR}/"* "${HELM_DIR}/${DIR}"
        fi
    done
done

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
  path: /instance_groups/name=${INSTANCE_GROUP}/jobs/name=${JOB}/properties?/quarks/pre_render_scripts/${TYPE}/-
  value: |
EOT
    sed 's/^/    /' < "${PRE_RENDER_SCRIPT}" >> "${OUTPUT}"
done

echo "operatorChartUrl: \"$(cf_operator_url)\"" > "${HELM_DIR}/Metadata.yaml"

ruby scripts/create_sample_values.rb "${HELM_DIR}/values.yaml" "${HELM_DIR}/sample-values.yaml"
MODE=check ruby scripts//create_sample_values.rb "${HELM_DIR}/values.yaml" "${HELM_DIR}/sample-values.yaml"

if [ -z "${NO_IMAGELIST:-}" ]; then
    ruby scripts/image_list.rb "${HELM_DIR}" | jq -r .images[] > "${HELM_DIR}/imagelist.txt"
fi

VERSION="$(./scripts/version.sh)"
helm package "${HELM_DIR}" --version "${VERSION}" --app-version "${VERSION}" --destination output/

HELM_CHART="output/kubecf-${VERSION}.tgz"
if [[ -n "${TARGET_FILE:-}" && "${TARGET_FILE}" != "${HELM_CHART}" ]]; then
    mkdir -p "$(dirname "${TARGET_FILE}")"
    cp "${HELM_CHART}" "${TARGET_FILE}"
fi
