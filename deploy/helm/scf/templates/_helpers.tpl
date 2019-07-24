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
