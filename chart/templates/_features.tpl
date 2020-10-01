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
  {{- if eq $.Values.features.blobstore.provider "s3" }}
    {{- $_ := merge $.Values (dict "features" (dict "external_blobstore" (dict "enabled" true))) }}
  {{- else }}
    {{- $_ := merge $.Values (dict "features" (dict "external_blobstore" (dict "enabled" false))) }}
  {{- end}}
{{- end }}
