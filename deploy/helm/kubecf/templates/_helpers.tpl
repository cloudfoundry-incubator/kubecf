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

{{/*
Returns a JSON map with the stemcell information based on the defaults
and possible overrides for the respective release.
*/}}
{{- define "kubecf.stemcellLookup" }}
  {{- $releasesMap := index . 0 }}
  {{- $releaseName := index . 1 }}
  {{- $result := dict  "os" (index $releasesMap "defaults" "stemcell" "os")  "version" (index $releasesMap "defaults" "stemcell" "version") }}

  {{- if index $releasesMap $releaseName }}
    {{- if index $releasesMap $releaseName "stemcell" }}
      {{- if index $releasesMap $releaseName "stemcell" "os" }}
        {{- $_ := set $result "os" (index $releasesMap $releaseName "stemcell" "os") }}
      {{- end }}

      {{- if index $releasesMap $releaseName "stemcell" "version" }}
        {{- $_ := set $result "version" (index $releasesMap $releaseName "stemcell" "version") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- toJson $result }}
{{- end }}

{{/*
Returns the release URL to use; if there is an override, use that, otherwise
use the default.

Usage:
  - path: /releases/name=foo/url
    type: replace
    value: {{ include "kubecf.releaseURLLookup" (list .Values.releases "foo") }}
*/}}
{{- define "kubecf.releaseURLLookup" }}
  {{- $releasesMap := index . 0 }}
  {{- $releaseName := index . 1 }}
  {{- (default (index $releasesMap "defaults" "url") (index (default (dict) (index $releasesMap $releaseName)) "url")) }}
{{- end }}
