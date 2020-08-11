{{- /*
==========================================================================================
| _releases.update $
+-----------------------------------------------------------------------------------------
| Create an entry in $.kubecf.releases for each release in the deployment manifest
| (if it doesn't already exist), and set the release version from the manifest.  The
| config/releases.yaml file can override the version, or disable the release altogether.
|
| Finally apply defaults from $.kubecf.releases.$defaults to fill in any missing values.
==========================================================================================
*/}}
{{- define "_releases.update" }}
  {{- $_ := include "_config.lookupManifest" (list $ "releases") }}
  {{- range $release := $.kubecf.retval }}
    {{- /* Only thing we need from the manifest is the release version */}}
    {{- $existing_release := index $.kubecf.config.releases $release.name }}
    {{- if $existing_release }}
      {{- if not $existing_release.version }}
        {{- $_ := set $existing_release "version" $release.version }}
      {{- end }}
    {{- else }}
      {{- $_ := set $.kubecf.config.releases $release.name (dict "version" $release.version) }}
    {{- end }}
  {{- end }}
  {{- $_ := include "_releases.applyDefaults" $.kubecf.config.releases }}
{{- end }}

{{- /*
==========================================================================================
| _releases.applyDefaults $releases
+-----------------------------------------------------------------------------------------
| Go through each entry in $releases and fill in missing values from $releases.$defaults
| (it that exists). The $defaults meta-release will be deleted before this function returns,
| to avoid it from overriding the $.kubecf.releases.$defaults.
==========================================================================================
*/}}
{{- define "_releases.applyDefaults" }}
  {{- $releases := . }}
  {{- $defaults := index $releases "$defaults" }}
  {{- $_ := unset $releases "$defaults" }}

  {{- if $defaults }}
    {{- $default_stemcell := index $defaults "stemcell" }}
    {{- $default_url := index $defaults "url" }}
    {{- range $name, $release := $releases }}
      {{- if and $default_url (not (hasKey $release "url")) }}
        {{- $_ := set $release "url" $default_url }}
      {{- end }}
      {{- if $default_stemcell }}
        {{ if hasKey $release "stemcell" }}
          {{ if and (hasKey $default_stemcell "os") (not (hasKey $release.stemcell "os")) }}
            {{- $_ := set $release.stemcell "os" $default_stemcell.os }}
          {{- end }}
          {{ if and (hasKey $default_stemcell "version") (not (hasKey $release.stemcell "version")) }}
            {{- $_ := set $release.stemcell "version" $default_stemcell.version }}
          {{- end }}
        {{- else }}
          {{- $_ := set $release "stemcell" $default_stemcell }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

