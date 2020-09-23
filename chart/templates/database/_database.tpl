{{- /*
==========================================================================================
| _database.load $
+-----------------------------------------------------------------------------------------
| Examines the features enabled, and places a list of databases we use into $.databases
|
| After running this, $.databases will be a dictionary, where the keys are the databases
| we will use, and the values are the secret in which the password is held (without the
| `var-` prefix and the `-database-password` suffix).
==========================================================================================
*/}}
{{- define "_database.load" }}
  {{- if not $.databases }}
    {{- $_ := set $ "databases" dict }}
  {{- end }}
  {{- $_ := set $.databases "cloud_controller" "cc" }}
  {{- $_ := set $.databases "diego" "diego" }}
  {{- $_ := set $.databases "network_connectivity" "network-connectivity" }}
  {{- $_ := set $.databases "network_policy" "network-policy" }}
  {{- $_ := set $.databases "uaa" "uaa" }}
  {{- $_ := set $.databases "locket" "locket" }}

  {{- if .Values.features.credhub.enabled }}
    {{- $_ := set $.databases "credhub" "credhub" }}
  {{- end }}

  {{- if .Values.features.routing_api.enabled }}
    {{- $_ := set $.databases "routing-api" "routing-api" }}
  {{- end }}

  {{- if .Values.features.autoscaler.enabled }}
    {{- if .Values.features.autoscaler.mysql.enabled }}
      {{- $_ := set $.databases "autoscaler" "autoscaler" }}
    {{- end }}
  {{- end }}
{{- end }}
