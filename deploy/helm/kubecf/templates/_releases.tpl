{{- /*
==========================================================================================
| _releases.update $
+-----------------------------------------------------------------------------------------
| Create an entry in $.Values.releases for each release in the deployment manifest
| (if it doesn't already exist), and set the release version from the manifest.  The
| config/releases.yaml file can override the version, or disable the release altogether.
|
| Finally apply defaults from $.Values.releases.$defaults to fill in any missing values.
==========================================================================================
*/}}
{{- define "_releases.update" }}
  {{- $_ := include "_config.lookupManifest" (list $ "releases") }}
  {{- range $release := $.kubecf.retval }}
    {{- /* Only thing we need from the manifest is the release version */}}
    {{- $existing_release := index $.Values.releases $release.name }}
    {{- if $existing_release }}
      {{- if not $existing_release.version }}
        {{- $_ := set $existing_release "version" $release.version }}
      {{- end }}
    {{- else }}
      {{- $_ := set $.Values.releases $release.name (dict "version" $release.version) }}
    {{- end }}
  {{- end }}
  {{- $_ := include "_releases.applyDefaults" $.Values.releases }}
{{- end }}

{{- /*
==========================================================================================
| _releases.applyDefaults $releases
+-----------------------------------------------------------------------------------------
| Go through each entry in $releases and fill in missing values from $releases.$defaults
| (if that exists). The $defaults meta-release will be deleted before this function returns,
| to avoid it from overriding $.Values.releases.$defaults.
==========================================================================================
*/}}
{{- define "_releases.applyDefaults" }}
  {{- $releases := . }}
  {{- $defaults := index $releases "$defaults" }}
  {{- $_ := unset $releases "$defaults" }}

  {{- if $defaults }}
    {{- range $name, $release := $releases }}
      {{- $_ := set $releases $name (merge $release $defaults) }}
    {{- end }}
  {{- end }}
{{- end }}
