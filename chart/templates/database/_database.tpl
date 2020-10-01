{{- /*
==========================================================================================
| _database.update $
+-----------------------------------------------------------------------------------------
| Examines the features enabled, and places a list of databases we use into
| $.kubecf.databases
|
| After running this, $.kubecf.databases will be a dictionary, where the keys are the
| databases we will use, and the values are the secret in which the password is held
| (without the `var-` prefix and the `-database-password` suffix).
==========================================================================================
*/}}
{{- define "_database.update" }}
  {{- if not $.kubecf.databases }}
    {{- $_ := set $.kubecf "databases" dict }}
  {{- end }}
  {{- $_ := set $.kubecf.databases "cloud_controller" "cc" }}
  {{- $_ := set $.kubecf.databases "diego" "diego" }}
  {{- $_ := set $.kubecf.databases "network_connectivity" "network-connectivity" }}
  {{- $_ := set $.kubecf.databases "network_policy" "network-policy" }}
  {{- $_ := set $.kubecf.databases "uaa" "uaa" }}
  {{- $_ := set $.kubecf.databases "locket" "locket" }}

  {{- if .Values.features.credhub.enabled }}
    {{- $_ := set $.kubecf.databases "credhub" "credhub" }}
  {{- end }}

  {{- if .Values.features.routing_api.enabled }}
    {{- $_ := set $.kubecf.databases "routing-api" "routing-api" }}
  {{- end }}

  {{- if .Values.features.autoscaler.enabled }}
    {{- if .Values.features.autoscaler.mysql.enabled }}
      {{- $_ := set $.kubecf.databases "autoscaler" "autoscaler" }}
    {{- end }}
  {{- end }}
{{- end }}
