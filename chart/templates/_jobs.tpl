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
  {{- range $mf_ig := $.kubecf.retval }}
    {{- /* Groups missing under `jobs` are added */}}
    {{- if not (hasKey $.Values.jobs $mf_ig.name) }}
      {{- $_ := set $.Values.jobs $mf_ig.name dict }}
    {{- end }}

    {{- $ig := index $.Values.jobs $mf_ig.name }}
    {{- /* Iterate jobs of the group (in the manifest) */}}
    {{- range $mf_job := $mf_ig.jobs }}
      {{- if not (hasKey $ig $mf_job.name) }}
        {{- $_ := set $ig $mf_job.name dict }}
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

  {{- /* Iterate the groups (in jobs) */}}
  {{- range $igname, $ig := $.Values.jobs }}
    {{- /* Get the fallback condition */}}
    {{- $default := index $ig "$default" }}
    {{- $_ := unset $ig "$default" }}
    {{- /* Iterate the jobs */}}
    {{- range $jobname, $job := $ig }}
      {{- $condition := default $default $job }}
      {{- if kindIs "map" $job }}
        {{- $condition = default $default (index $job "condition") }}
      {{- else }}
        {{- $job = dict "condition" $condition }}
        {{- $_ := set $ig $jobname $job }}
      {{- end }}
      {{- /* Resolve the conditions to plain boolean true/false */}}
      {{- $_ := set $job "condition" (eq "true" (include "_config.condition" (list $ $condition))) }}
      {{- if not (hasKey $job "processes") }}
        {{- $_ := set $job "processes" (list $jobname) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
