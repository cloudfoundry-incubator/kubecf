#!/bin/bash

# This is a helper script which combines a helm chart tarball and an image list
# into a new tarball.

KUBECF_CHART="$1"
KUBECF_IMAGE_LIST_JSON_FILE="$2"
OUTPUT="$3"
JQ="$4"
HELM="$5"

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

mkdir kubecf/templates
cat <<EOF > kubecf/templates/NOTES.txt
    Welcome to your new deployment of kubecf.

    The endpoint for use by the `cf` client is
        [1;36mhttps://api.{{ .Values.env.DOMAIN }}[0m

    To target this endpoint and login, run
        [1;36mcf login --skip-ssl-validation -a https://api.{{ .Values.env.DOMAIN }} -u admin[0m

    Please remember, it may take some time for everything to come online.

    You can use
        [1;36mkubectl get pods --namespace {{ .Release.Namespace }}[0m

    to spot-check if everything is up and running, or
        [1;36mwatch -c 'kubectl get pods --namespace {{ .Release.Namespace }}'[0m

    to monitor continuously.

    The online documentation (release notes, deployment guide) can be found at
        [1;36mhttps://www.suse.com/documentation/cloud-application-platform-1[0m
{{- if and .Values.enable.eirini (ne (toString .Values.env.KUBE_CSR_AUTO_APPROVAL) "true") }}

    [1;31mThe secret generator will create a certificate signing request that
    must be approved by an administrator before deployment will continue.
    To do so run the command[0m
        [1;32mkubectl certificate approve {{ .Release.Namespace }}-bits-service-ssl-cert[0m
{{- end }}
EOF

"${HELM}" package kubecf/

mv kubecf-*.tgz "${OUTPUT}"
