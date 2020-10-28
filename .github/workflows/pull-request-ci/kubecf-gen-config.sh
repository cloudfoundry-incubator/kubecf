#!/usr/bin/env bash

# This is called in the `Generate KubeCF Configuration` step of `pull-request-ci.yaml`

set -o errexit -o nounset -o pipefail

make -C "${GITHUB_WORKSPACE}/catapult" kubecf-gen-config

cd "${GITHUB_WORKSPACE}/catapult/build${BACKEND}"

gomplate --context .=scf-config-values.yaml <<"EOF" \
> "${GITHUB_WORKSPACE}/kubecf/dev/kubecf/kubecf-values.yaml"
{{- /* Disable brain minibroker tests */}}
{{- define "minibroker-tests" }}
properties:
    brain-tests:
        acceptance-tests-brain:
            tests:
                minibroker:
                    {{- range slice "mariadb" "mongodb" "postgres" "redis" }}
                    {{ . }}:
                        enabled: false
                    {{- end }}
{{- end }}
{{- $ = tmpl.Exec "minibroker-tests" | yaml | merge $ }}

{{- /* Disable registry overrides */}}
{{- $ = coll.Omit "kube" $ }}

{{- /* Set DNS annotations */}}
{{- define "svc_annotation" }}
services:
    {{ index . 0 }}:
        annotations:
            "external-dns.alpha.kubernetes.io/hostname": {{ index . 1 }}
    {{- end }}
{{- $d := .system_domain }}
{{- $ = printf "%s, *.%s" $d $d | slice "router" | tmpl.Exec "svc_annotation" | yaml | merge $ }}
{{- $ = printf "ssh.%s" $d | slice "ssh-proxy" | tmpl.Exec "svc_annotation" | yaml | merge $ }}
{{- $ = printf "tcp.%s, *.tcp.%s" $d $d | slice "tcp-router" | tmpl.Exec "svc_annotation" | yaml | merge $ }}

{{- $ | toYAML }}
EOF

echo "::group::scf-config-values.yaml"
cat "${GITHUB_WORKSPACE}/kubecf/dev/kubecf/kubecf-values.yaml"
echo "::endgroup"
