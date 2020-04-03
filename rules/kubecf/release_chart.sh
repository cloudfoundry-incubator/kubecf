#!/bin/bash

# This is a helper script which combines a helm chart tarball and an image list
# into a new tarball.

if [ ! -e "$1" ]; then
  echo "Helm chart tarball '$1' does not exist, bailing out!"; exit 1
fi

if [ ! -e "$2" ]; then
  echo "Image list '$2' has not been created, bailing out!"; exit 1
fi

BASENAME=$(dirname $(tar tf "$1" | head -n1))
KUBECF_IMAGELIST_TXT_PATH="${BASENAME}/imagelist.txt"
JQ_PATH="$4"

tar xfv "$1"
$JQ_PATH '.images | .[]' -r < $2 > "${KUBECF_IMAGELIST_TXT_PATH}"

tar czf "$3" "${BASENAME}/"
