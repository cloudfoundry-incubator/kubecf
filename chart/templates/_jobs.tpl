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
    {{- /* Groups missing under `jobs` are added, with defaults */}}
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
      {{- /* Job missing in group is added, with defaults:
           * - nil condition (to use fallback)
           * - single process, equals job
           */}}
      {{- if not (hasKey $ig $mf_job.name) }}
        {{- $_ := set $ig $mf_job.name (dict "condition" nil "processes" (list $mf_job.name)) }}
      {{- end }}
      {{- /* Job with string data (condition!) is expanded to full map.
           * Sets default for processes: single, equals job.
           */}}
      {{ $data := index $ig $mf_job.name }}
      {{- if kindIs "invalid" $data }}
        {{- $_ := set $ig $mf_job.name (dict "condition" nil "processes" (list $mf_job.name)) }}
      {{- else if not (kindIs "map" $data) }}
        {{- $_ := set $ig $mf_job.name (dict "condition" $data "processes" (list $mf_job.name)) }}
      {{- end }}
      {{- /* Job with partial data is completed. */}}
      {{ $job := index $ig $mf_job.name }}
      {{- if not (hasKey $job "condition") }}
        {{- $_ := set $job "condition" nil }}
      {{- end }}
      {{- if not (hasKey $job "processes") }}
        {{- $_ := set $job "processes" (list $mf_job.name) }}
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
    {{- range $jobname, $job := $ig }}
      {{- $condition := index $job "condition" }}
      {{- /* Resolve missing (nil) conditions to the fallback condition */}}
      {{- if kindIs "invalid" $condition }}
        {{- $_ := set $job "condition" $default }}
      {{- end }}
      {{- /* Resolve condition to a boolean here */}}
      {{- $condition := index $job "condition" }}
      {{- $_ := set $job "condition" (eq "true" (include "_config.condition" (list $ $condition))) }}
    {{- end }}
  {{- end }}
{{- end }}
