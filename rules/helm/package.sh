#!/usr/bin/env bash

set -o errexit -o nounset

build_dir="tmp/build/${PACKAGE_DIR}"
mkdir -p "${build_dir}"
cp --dereference --recursive "${PACKAGE_DIR}"/* "${build_dir}"

for t in ${TARS}; do
  tar xf "${t}" -C "${build_dir}"
done

"${HELM}" init --client-only > /dev/null
"${HELM}" package "${build_dir}" \
  --version="${CHART_VERSION}" \
  --app-version="${APP_VERSION}" > /dev/null

mv "${OUTPUT_FILENAME}" "${OUTPUT_TGZ}"
