#!/usr/bin/env bash

set -o errexit -o nounset

dockerfile_path_real=$(readlink "{dockerfile_path}")
dockerfile_dirname=$(dirname "${dockerfile_path_real}")

cd "${dockerfile_dirname}"

heroku container:push \
  --recursive \
  --app "{app_name}" \
  --arg "DRONE_IMAGE=drone/drone:{drone_image_version}@sha256:{drone_image_sha256},DRONE_CONVERT_STARLARK_IMAGE=drone/drone-convert-starlark@sha256:{drone_convert_starlark_image_sha256}"

heroku container:release web \
  --app "{app_name}"
