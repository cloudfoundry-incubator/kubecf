{{- /*
==========================================================================================
| _features.update $
+-----------------------------------------------------------------------------------------
| Normalize feature settings so that they can be used as booleans in
| "condition" expressions.
==========================================================================================
*/}}
{{- define "_features.update" }}
  {{- /* Translate blobstore.provider feature into a proper boolean we can query in the conditions */}}
  {{- if eq $.Values.features.blobstore.provider "singleton" }}
    {{- $_ := merge $.Values (dict "features" (dict "external_blobstore" (dict "enabled" false))) }}
  {{- else }}
    {{- $_ := merge $.Values (dict "features" (dict "external_blobstore" (dict "enabled" true))) }}
  {{- end}}
  {{- /* Fix routing_api to proper (per-scheduler) default when not overriden by user */}}
  {{- if kindIs "invalid" $.Values.features.routing_api.enabled }}
    {{- $_ := set $.Values.features.routing_api "enabled" (not $.Values.features.eirini.enabled) }}
  {{- end }}
{{- end }}
