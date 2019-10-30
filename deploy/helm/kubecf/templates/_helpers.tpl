{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "scf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "scf.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "scf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get the metadata name for an ops file.
*/}}
{{- define "scf.ops-name" -}}
{{- printf "ops-%s" (base . | trimSuffix (ext .) | lower | replace "_" "-") -}}
{{- end -}}

{{- /*
  Template "scf.dig" takes a dict and a list; it indexes the dict with each
  successive element of the list.

  For example, given (using JSON prepresentations)
    $a = { foo: { bar: { baz: 1 } } }
    $b = [ foo bar baz ]
  Then `template "scf.dig" $a $b` will return "1".

  Note that if the key is missing there will be a rendering error.
*/ -}}
{{- define "scf.dig" }}
{{- $obj := first . }}
{{- $keys := last . }}
{{- range $key := $keys }}{{ $obj = index $obj $key }}{{ end }}
{{- $obj | quote }}
{{- end }}

{{/*
Flatten the `toFlatten` map into `flattened`. The `flattened` map contains only one layer of keys
flattened and separated by `separator`.
*/}}
{{- define "scf.flatten" -}}
  {{- $flattened := index . "flattened" }}
  {{- $toFlatten := index . "toFlatten" }}
  {{- $separator := hasKey . "separator" | ternary (index . "separator") "/" }}
  {{- $_prefix := hasKey . "_prefix" | ternary (index . "_prefix") "" }}

  {{- if (kindIs "map" $toFlatten) }}
    {{- range $key, $value := $toFlatten }}
      {{- $newPrefix := printf "%s%s%s" $_prefix $separator $key }}
      {{- include "scf.flatten" (dict "flattened" $flattened "toFlatten" $value "_prefix" $newPrefix "separator" $separator) }}
    {{- end }}
  {{- else }}
    {{- $key := $_prefix }}
    {{- $value := $toFlatten }}
    {{- $_ := set $flattened $key $value }}
  {{- end }}
{{- end -}}
