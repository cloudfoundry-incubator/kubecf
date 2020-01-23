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

version='v0.0.0-{{ (ds "workspace_status").STABLE_GIT_COMMIT_SHORT }}'
# If the branch name is a valid SemVer, use it as the chart version.
if [[ -n "$(echo '{{ (ds "workspace_status").STABLE_GIT_BRANCH }}' | awk '/(?in)^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-([a-z-][\da-z-]+|[\da-z-]+[a-z-][\da-z-]*|0|[1-9]\d*)(\.([a-z-][\da-z-]+|[\da-z-]+[a-z-][\da-z-]*|0|[1-9]\d*))*)?(\+[\da-z-]+(\.[\da-z-]+)*)?$/ { print $0 }')" ]]; then
  version='{{ (ds "workspace_status").STABLE_GIT_BRANCH }}'
fi

output=$("${HELM}" package "${build_dir}" \
  --version="${version}" \
  --app-version="${version}" \
  | awk 'match($0, /Successfully packaged chart and saved it to: (.*)/, path) { print path[1] }')

mv "${output}" "${OUTPUT_TGZ}"
