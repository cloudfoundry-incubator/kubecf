#!/usr/bin/env bash

set -o errexit -o nounset

dockerfile_path_real=$(readlink "{dockerfile_path}")
dockerfile_dirname=$(dirname "${dockerfile_path_real}")

cd "${dockerfile_dirname}"

heroku container:push \
  --recursive \
  --app "{app_name}" \
  --arg "IMAGE=drone/drone:{drone_image_version}@sha256:{drone_image_sha256}"

heroku container:release web \
  --app "{app_name}"
