#!/bin/bash

# This is a helper script which combines a helm chart tarball and an image list
# into a new tarball.

KUBECF_CHART="$1"
KUBECF_IMAGE_LIST_JSON_FILE="$2"
OUTPUT="$3"
JQ="$4"

if [ ! -e "${KUBECF_CHART}" ]; then
  >&2 echo "Helm chart tarball '${KUBECF_CHART}' does not exist, bailing out!"; exit 1
fi

if [ ! -e "${KUBECF_IMAGE_LIST_JSON_FILE}" ]; then
  >&2 echo "Image list '${KUBECF_IMAGE_LIST_JSON_FILE}' has not been created, bailing out!"; exit 1
fi

BASENAME=$(dirname "$(tar tf "${KUBECF_CHART}" | head -n1)")
KUBECF_IMAGE_LIST_TXT_FILE="${BASENAME}/imagelist.txt"

tar xf "${KUBECF_CHART}"
"${JQ}" '.images | .[]' -r \
  < "${KUBECF_IMAGE_LIST_JSON_FILE}" \
  > "${KUBECF_IMAGE_LIST_TXT_FILE}"

helm package kubecf/

mv kubecf-*.tgz "${OUTPUT}"
