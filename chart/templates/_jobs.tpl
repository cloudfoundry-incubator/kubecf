{{- /*
==========================================================================================
| _jobs.update $
+-----------------------------------------------------------------------------------------
| Create an entry in $.Values.jobs for each instance group in the deployment
| manifest (if it doesn't already exist), and each job in the group (again, if
| it doesn't already exist).  The config/jobs.yaml file can override the groups
| and jobs. As part of this it also adds missing '$default' keys, and uses '$default'
| to resolve missing condition values.
|
| After filling the tree all feature conditions are resolved, i.e. turned into
| simple true/false.
==========================================================================================
*/}}
{{- define "_jobs.update" }}
  {{- /* Load the instance groups from the cf-deployment manifest */}}
  {{- $_ := include "_config.lookupManifest" (list $ "instance_groups") }}
  {{- /* Phase I - Fill missing entries with data from the manifest */}}
  {{- /* Iterate the groups (in the manifest) */}}
  {{- range $mf_ig := $.kubecf.retval }}
    {{- /* Groups missing under `jobs` are added, with a default */}}
    {{- if not (hasKey $.Values.jobs $mf_ig.name) }}
      {{- $_ := set $.Values.jobs $mf_ig.name (dict "$default" true) }}
    {{- end }}
    {{- $ig := index $.Values.jobs $mf_ig.name }}
    {{- /* Groups without a default get one */}}
    {{- if not (hasKey $ig "$default") }}
      {{- $_ := set $ig "$default" true }}
    {{- end }}
    {{- /* Iterate jobs of the group (in the manifest) */}}
    {{- range $mf_job := $mf_ig.jobs }}
      {{- /* Job missing in group is added, with nil condition (to use fallback) */}}
      {{- if not (hasKey $ig $mf_job.name) }}
        {{- $_ := set $ig $mf_job.name nil }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{/* -- Translate the non-standard blobstore.provider feature into
     * a proper boolean we can query in the conditions.
     */}}
  {{- if eq $.Values.features.blobstore.provider "s3" }}
    {{ $_ := merge $.Values (dict "features" (dict "external_blobstore" (dict "enabled" true))) }}
  {{- else }}
    {{ $_ := merge $.Values (dict "features" (dict "external_blobstore" (dict "enabled" false))) }}
  {{- end}}
  {{- /* Phase II - Resolve the conditions to plain true/false */}}
  {{- /* Iterate the groups (in jobs) */}}
  {{- range $igname, $ig := $.Values.jobs }}
    {{- /* Get the fallback condition */}}
    {{- $default := index $ig "$default" }}
    {{- $_ := unset $ig "$default" }}
    {{- /* Iterate the jobs */}}
    {{- range $jobname, $_ := $ig }}
      {{- /* Resolve missing (nil) conditions to the fallback condition */}}
      {{- if kindIs "invalid" $_ }}
        {{- $_ := set $ig $jobname $default }}
      {{- end }}
      {{- /* Resolve condition to a boolean here */}}
      {{- $_ := set $ig $jobname (eq "true" (include "_config.condition" (list $ (index $ig $jobname)))) }}
    {{- end }}
  {{- end }}
{{- end }}
