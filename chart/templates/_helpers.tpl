{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kubecf.name" }}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The name of the deployment.
*/}}
{{define "kubecf.deployment-name" -}}
kubecf
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubecf.fullname" }}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubecf.chart" }}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get the metadata name for an ops file.
*/}}
{{- define "kubecf.ops-name" }}
{{- printf "ops-%s" (base .Path | trimSuffix (ext .Path) | lower | replace "_" "-") }}
{{- end }}

{{- /*
==========================================================================================
| component.selector (list $ $component)
+-----------------------------------------------------------------------------------------
| Emit standard labels for use in selectors (for services and the like).
|
| $component should be the name of a component; ideally this will match the name of the
| service / pod.
==========================================================================================
*/ -}}
{{- define "component.selector" }}
{{- $root := first . }}
{{- $component := index . 1 }}
app.kubernetes.io/name: {{ include "kubecf.fullname" $root }}
app.kubernetes.io/instance: {{ $root.Release.Name | quote }}
app.kubernetes.io/component: {{ $component | quote }}
{{- end }}

{{- /*
==========================================================================================
| component.labels (list $ $component)
+-----------------------------------------------------------------------------------------
| Emit standard labels for use in pod/etc. declarations.
|
| $component should be the name of a component; ideally this will match the name of the
| service / pod.
|
| This will include any labels relevant for selectors.
==========================================================================================
*/ -}}
{{- define "component.labels" }}
{{- $root := first . }}
{{- $component := last . }}
{{- include "component.selector" . }}
app.kubernetes.io/managed-by: {{ $root.Release.Service | quote }}
app.kubernetes.io/version: {{ default $root.Chart.Version $root.Chart.AppVersion | quote }}
helm.sh/chart: {{ include "kubecf.chart" $root }}
{{- end }}

{{- /*
  Template "kubecf.dig" takes a dict and a list; it indexes the dict with each
  successive element of the list.

  For example, given (using JSON prepresentations)
    $a = { foo: { bar: { baz: 1 } } }
    $b = [ foo bar baz ]
  Then `template "kubecf.dig" $a $b` will return "1".

  Note that if the key is missing there will be a rendering error.
*/ -}}
{{- define "kubecf.dig" }}
{{- $obj := first . }}
{{- $keys := last . }}
{{- range $key := $keys }}{{ $obj = index $obj $key }}{{ end }}
{{- $obj | quote }}
{{- end }}

{{/*
Flatten the `toFlatten` map into `flattened`. The `flattened` map contains only one layer of keys
flattened and separated by `separator`.
*/}}
{{- define "kubecf.flatten" }}
  {{- $flattened := index . "flattened" }}
  {{- $toFlatten := index . "toFlatten" }}
  {{- $separator := hasKey . "separator" | ternary (index . "separator") "/" }}
  {{- $_prefix := hasKey . "_prefix" | ternary (index . "_prefix") "" }}

  {{- if (kindIs "map" $toFlatten) }}
    {{- range $key, $value := $toFlatten }}
      {{- $newPrefix := printf "%s%s%s" $_prefix $separator $key }}
      {{- include "kubecf.flatten" (dict "flattened" $flattened "toFlatten" $value "_prefix" $newPrefix "separator" $separator) }}
    {{- end }}
  {{- else }}
    {{- $key := $_prefix }}
    {{- $value := $toFlatten }}
    {{- $_ := set $flattened $key $value }}
  {{- end }}
{{- end }}
