#!/usr/bin/env bash

set -o errexit -o nounset

build_dir="tmp/build/${PACKAGE_DIR}"
mkdir -p "${build_dir}"

cp -L -R "${PACKAGE_DIR}"/* "${build_dir}"

# Generated files ( here TARS, GENERATED ) are not part of the source code
# to be able to use them, we have to copy them
for t in ${TARS}; do
  tar xf "${t}" -C "${build_dir}"  > /dev/null
done

for g in ${GENERATED}; do
  cp "${g}" "${build_dir}"/ > /dev/null
done

"${HELM}" init --client-only > /dev/null
"${HELM}" package "${build_dir}" \
  --version="${CHART_VERSION}" \
  --app-version="${APP_VERSION}" > /dev/null

mv "${OUTPUT_FILENAME}" "${OUTPUT_TGZ}"
