{{- /*
==========================================================================================
| _jobs.update $
+-----------------------------------------------------------------------------------------
| * Move some jobs from their manifest locations to other instance groups.
| * Create $.Values.jobs and $.Values.addon_jobs from the deployment manifest.
| * Define CC workers based on their property settings in both "jobs" and "resources" trees.
==========================================================================================
*/}}
{{- define "_jobs.update" }}
  {{- /* *** Move some jobs to new instance groups *** */}}
  {{- range $from_ig, $ig := $.Values.move_jobs }}
    {{- range $job, $to_ig := $ig }}
      {{- include "_jobs.move" (list $ $from_ig $to_ig $job) }}
    {{- end }}
  {{- end }}

  {{- /* *** Fill in $.Values.jobs and $.Values.addon_jobs from cf-manifest *** */}}
  {{- include "_jobs.fromManifest" (list $ $.Values.jobs "instance_groups") }}
  {{- include "_jobs.fromManifest" (list $ $.Values.addon_jobs "addons") }}

  {{- /* *** Define CC workers based on their property settings *** */}}
  {{- include "_jobs.defineWorkers" (list $ "api" "cloud_controller_ng" "local_worker" "local") }}
  {{- include "_jobs.defineWorkers" (list $ "cc-worker" "cloud_controller_worker" "worker" "generic") }}
{{- end }}

{{- /*
==========================================================================================
| _jobs.fromManifest $ $jobs $manifest_key
+-----------------------------------------------------------------------------------------
| * Load all instance groups and their jobs from the deployment manifest.
| * For data-only releases set the process list to the empty list.
| * If no process list is defined then set it to a single process with the same
|   name as the job.
| * Set default conditions for jobs based on the $default of the instance group.
| * Evaluate all conditions to a boolean value.
==========================================================================================
*/}}
{{- define "_jobs.fromManifest" }}
  {{- $root := index . 0 }}
  {{- $jobs := index . 1 }}
  {{- $mf_key := index . 2 }}

  {{- /* *** Load the instance groups from the cf-deployment manifest *** */}}
  {{- $_ := include "_config.lookupManifest" (list $root $mf_key) }}
  {{- range $mf_ig := $root.kubecf.retval }}
    {{- if not (hasKey $jobs $mf_ig.name) }}
      {{- $_ := set $jobs $mf_ig.name dict }}
    {{- end }}

    {{- $ig := index $jobs $mf_ig.name }}
    {{- range $mf_job := $mf_ig.jobs }}
      {{- if not (hasKey $ig $mf_job.name) }}
        {{- $_ := set $ig $mf_job.name dict }}
        {{- /* Data-only releases have an empty process list */}}
        {{- $release := index $root.Values.releases $mf_job.release }}
        {{- if index $release "data-only" }}
          {{- $_ := set (index $ig $mf_job.name) "processes" list }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* *** For each job fill in conditions from $default and evaluate into boolean *** */}}
  {{- range $ig_name, $ig := $jobs }}
    {{- /* Get the fallback condition */}}
    {{- $default := index $ig "$default" }}
    {{- $_ := unset $ig "$default" }}

    {{- range $job_name, $job := $ig }}
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
        {{- $_ := set $ig $job_name $job }}
      {{- end }}

      {{- /* Evaluate the conditions to plain boolean true/false value */}}
      {{- $_ := set $job "condition" (eq "true" (include "_config.condition" (list $root $condition))) }}

      {{- /* If process list doesn't exist create it with a single process name same as the job name */}}
      {{- if not (hasKey $job "processes") }}
        {{- $_ := set $job "processes" (list $job_name) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _jobs.defineWorkers $ $ig_name $job_name $process_name_root $scope
+-----------------------------------------------------------------------------------------
| * Define CC worker processes based on their "number_of_workers" property setting.
| * Since the default for the properties is not set in the deployment manifest,
|   it must be provided in config/jobs.yaml.
| * Create corresponding process entries in $.Values.resources for each new worker,
|   with default resource settings copied from "$worker" template.
==========================================================================================
*/}}
{{- define "_jobs.defineWorkers" }}
  {{- $root := index . 0 }}
  {{- $ig_name := index . 1 }}
  {{- $job_name := index . 2 }}
  {{- $process_name_root := index . 3 }}
  {{- $scope := index . 4 }}

  {{- /* Get normalized default resources for this type of worker process */}}
  {{- $resources_job := index $root.Values.resources $ig_name $job_name }}
  {{- $template := printf "$%s" $process_name_root }}
  {{- include "_resources.expandDefaults" (list $resources_job $template) }}
  {{- $resources_default := merge (index $resources_job $template) (index $resources_job $template "$defaults")}}
  {{- $_ := unset $resources_default "$defaults" }}
  {{- $_ := unset $resources_job $template }}

  {{- /* Get number of worker processes from cc.jobs properties */}}
  {{- $property := printf "cc.jobs.%s.number_of_workers" $scope }}
  {{- $workers := include "_config.property" (list $root $ig_name $job_name $property) | int }}

  {{- $job := index $root.Values.jobs $ig_name $job_name }}

  {{- range $worker := until $workers }}
    {{- $process_name := printf "%s_%d" $process_name_root (add1 $worker) }}
    {{- $_ := set $job "processes" (append $job.processes $process_name) }}

    {{- /* Merge resource defaults from template with user overrides */}}
    {{- include "_resources.expandDefaults" (list $resources_job $process_name) }}
    {{- $process := index $resources_job $process_name }}
    {{- $_ := set $process "$defaults" (merge (index $process "$defaults") $resources_default) }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _jobs.move $ $from_ig_name $to_ig_name $job_name
+-----------------------------------------------------------------------------------------
| Move a job from one instance group to another, creating the destination instance
| group if it doesn't exist yet.
==========================================================================================
*/}}
{{- define "_jobs.move" }}
  {{- $root := index . 0 }}
  {{- $from_ig_name := index . 1 }}
  {{- $to_ig_name := index . 2 }}
  {{- $job_name := index . 3 }}

  {{- /* Locate $from_ig in the manifest */}}
  {{- $_ := include "_config.lookupManifest" (list $root "instance_groups" $from_ig_name) }}
  {{- $from_ig := $root.kubecf.retval }}
  {{- if not $from_ig }}
    {{- include "_config.fail" (printf "Could not find instance group %q while moving job %q" $from_ig_name $job_name) }}
  {{- end }}

  {{- /* Find (and remove) the job from the $from_ig jobs list */}}
  {{- $from_job := "" }}{{/* cannot use untyped nil when assigning to variable */}}
  {{- $from_jobs := list }}
  {{- range $job := $from_ig.jobs }}
    {{- if eq $job.name $job_name }}
      {{- $from_job = $job }}
    {{- else }}
      {{- $from_jobs = append $from_jobs $job }}
    {{- end }}
  {{- end }}
  {{- $_ := set $from_ig "jobs" $from_jobs }}
  {{- if not $from_job }}
    {{- include "_config.fail" (printf "Instance group %q doesn't include job %q" $from_ig_name $job_name) }}
  {{- end }}

  {{- /* Find (or create) $to_ig in the manifest */}}
  {{- $_ := include "_config.lookupManifest" (list $root "instance_groups" $to_ig_name) }}
  {{- $to_ig := $root.kubecf.retval }}
  {{- if not $to_ig }}
    {{- $to_ig = dict "name" $to_ig_name "stemcell" "default" "instances" $from_ig.instances "jobs" list }}
    {{- $manifest := $root.kubecf.manifest }}
    {{- $_ := set $manifest "instance_groups" (append $manifest.instance_groups $to_ig) }}
  {{- end }}

  {{- /* Move the job to $to_ig jobs list */}}
  {{- $_ := set $to_ig "jobs" (append $to_ig.jobs $from_job) }}
{{- end }}
