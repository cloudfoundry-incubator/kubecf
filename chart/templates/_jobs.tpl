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
        {{- /* Data-only releases have an empty process list */}}
        {{- $release := index $.Values.releases $mf_job.release }}
        {{- if index $release "data-only" }}
          {{- $_ := set (index $ig $mf_job.name) "processes" list }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Move some jobs to new instance groups */}}
  {{- range $from_ig, $ig := index $.Values.jobs "$move" }}
    {{- range $job, $to_ig := $ig }}
      {{- include "_jobs.move" (list $.Values.jobs $from_ig $to_ig $job) }}
    {{- end }}
  {{- end }}
  {{- $_ := unset $.Values.jobs "$move" }}

  {{- /* Translate blobstore.provider feature into a proper boolean we can query in the conditions */}}
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

    {{- range $jobname, $job := $ig }}
      {{- $condition := $job }}
      {{- if kindIs "map" $job }}
        {{- $condition = index $job "condition" }}
      {{- end }}
      {{- /* Check for nil because false is a valid condition and should not be replaced by $default */}}
      {{- if kindIs "invalid" $condition }}
        {{- $condition = $default }}
      {{- end }}
      {{- if not (kindIs "map" $job) }}
        {{- $job = dict }}
        {{- $_ := set $ig $jobname $job }}
      {{- end }}

      {{- /* Resolve the conditions to plain boolean true/false */}}
      {{- $_ := set $job "condition" (eq "true" (include "_config.condition" (list $ $condition))) }}
      {{- if not (hasKey $job "processes") }}
        {{- $_ := set $job "processes" (list $jobname) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Define all api local worker processes */}}
  {{- $job := $.Values.jobs.api.cloud_controller_ng }}
  {{- $resources := index $.Values.resources.api.cloud_controller_ng "$local_worker" }}
  {{- $workers := include "_config.property" (list $ "api" "cloud_controller_ng" "cc.jobs.local.number_of_workers") | int }}
  {{- range $worker := until $workers }}
    {{- $process_name := printf "local_worker_%d" (add1 $worker) }}
    {{- $_ := set $job "processes" (append $job.processes $process_name) }}
    {{- $_ := set $.Values.resources.api.cloud_controller_ng $process_name $resources }}
  {{- end }}
  {{- $_ := unset $.Values.resources.api.cloud_controller_ng "$local_worker" }}

  {{- /* Define all cc-worker generic worker processes */}}
  {{- $job := index $.Values.jobs "cc-worker" "cloud_controller_worker" }}
  {{- $resources := index $.Values.resources "cc-worker" "cloud_controller_worker" "$worker" }}
  {{- $workers := include "_config.property" (list $ "cc-worker" "cloud_controller_worker" "cc.jobs.generic.number_of_workers") | int }}
  {{- range $worker := until $workers }}
    {{- $process_name := printf "worker_%d" (add1 $worker) }}
    {{- $_ := set $job "processes" (append $job.processes $process_name) }}
    {{- $_ := set (index $.Values.resources "cc-worker" "cloud_controller_worker") $process_name $resources }}
    {{- $_ := set $job "processes" (append $job.processes (printf "worker_%d" (add1 $worker))) }}
  {{- end }}
  {{- $_ := unset (index $.Values.resources "cc-worker" "cloud_controller_worker") "$worker" }}

{{- end }}

{{- /*
==========================================================================================
| _jobs.move $.Values.jobs $from_ig $to_ig $job
+-----------------------------------------------------------------------------------------
| Move a job from one instance group to another, creating the destination instance
| group if it doesn't exist yet. The new instance group will *not* inherit the default
| condition from the old instance group.
==========================================================================================
*/}}
{{- define "_jobs.move" }}
  {{- $jobs := index . 0 }}
  {{- $from_ig := index . 1 }}
  {{- $to_ig := index . 2 }}
  {{- $job := $to_ig }}
  {{- if gt (len .) 3 }}
    {{- $job = index . 3 }}
  {{- end }}

  {{- $ig := index $jobs $from_ig }}
  {{- if kindIs "invalid" (index $ig $job) }}
    {{- include "_config.fail" (printf "Job %q in instance group %q does not exist" $job $from_ig) }}
  {{- end }}

  {{- if not (hasKey $jobs $to_ig) }}
    {{- $_ := set $jobs $to_ig dict }}
  {{- end }}

  {{- $_ := set (index $jobs $to_ig) $job (index $ig $job) }}
  {{- $_ := unset $ig $job }}
{{- end }}
