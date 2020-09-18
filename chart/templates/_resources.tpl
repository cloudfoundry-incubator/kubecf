{{- /*
==========================================================================================
| _resources.update $
+-----------------------------------------------------------------------------------------
| Update $.Values.resources and $.Values.addon_resources.
==========================================================================================
*/}}
{{- define "_resources.update" }}
  {{- include "_resources._update" (list $ "resources" "jobs") }}
  {{- include "_resources._update" (list $ "addon_resources" "addon_jobs") }}
{{- end }}

{{- /*
==========================================================================================
| _resources._update $ $resources_name $jobs_name
+-----------------------------------------------------------------------------------------
| * Create an entry in $resources for each instance group in $jobs, and each job
|   in each group, and each process in each job. Verify that each ig, job, process
|   in $resources also exists in $jobs.
| * Apply defaults from each level off the tree to fill in missing entries in the
|   resources definitions.
| * Remove jobs whose "condition" is false.
==========================================================================================
*/}}
{{- define "_resources._update" }}
  {{- $root := index . 0 }}
  {{- $resources_name := index . 1 }}
  {{- $jobs_name := index . 2 }}

  {{- $resources := index $root.Values $resources_name }}
  {{- $jobs := index $root.Values $jobs_name }}

  {{- include "_resources.expandDefaults" (list $resources "$defaults") }}

  {{- /* Fill missing resources entries with data from jobs tree. */}}
  {{- range $jobs_ig_name, $jobs_ig := $jobs }}
    {{- include "_resources.expandDefaults" (list $resources $jobs_ig_name) }}

    {{- $resources_ig := index $resources $jobs_ig_name }}
    {{- range $job_name, $jobs_job := $jobs_ig }}
      {{- include "_resources.expandDefaults" (list $resources_ig $job_name) }}

      {{- $resources_job := index $resources_ig $job_name }}
      {{- range $process_name := $jobs_job.processes }}
        {{- include "_resources.expandDefaults" (list $resources_job $process_name) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- $global_defaults := index $resources "$defaults" }}
  {{- $_ := unset $resources "$defaults" }}

  {{- /* Verify that each entry in the 'resources' tree also has a 'jobs' entry */}}
  {{- $fail_suffix := printf " defined in %s but not in %s" $resources_name $jobs_name }}
  {{- range $ig_name, $ig := $resources }}
    {{- if not (hasKey $jobs $ig_name) }}
      {{- include "_config.fail" (printf "Instance group %q%s" $ig_name $fail_suffix) }}
    {{- end }}

    {{- $jobs_ig := index $jobs $ig_name }}
    {{- $ig_defaults := index $ig "$defaults" }}
    {{- $_ := unset $ig "$defaults" }}

    {{- range $job_name, $job := $ig }}
      {{- if not (hasKey $jobs_ig $job_name) }}
        {{- include "_config.fail" (printf "Instance group %q job %q%s" $ig_name $job_name $fail_suffix) }}
      {{- end }}

      {{- $jobs_job := index $jobs_ig $job_name }}
      {{- $job_defaults := index $job "$defaults" }}
      {{- $_ := unset $job "$defaults" }}

      {{- range $process_name, $process := $job }}
        {{- if not (has $process_name $jobs_job.processes) }}
          {{- include "_config.fail" (printf "Instance group %q job %q process %q%s" $ig_name $job_name $process_name $fail_suffix) }}
        {{- end }}

        {{- $process_defaults := index $process "$defaults" }}
        {{- $_ := unset $process "$defaults" }}

        {{- $merged := merge $process $process_defaults $job_defaults $ig_defaults $global_defaults }}

        {{- /* Default memory request is a percentage of the limit, at least a minimum, but never more than the limit itself */}}
        {{- if and $merged.memory.limit (not $merged.memory.request) }}
          {{- $request := div (mul $merged.memory.limit $root.Values.features.memory_limits.default_request_in_percent) 100 }}
          {{- $request = $request | max $root.Values.features.memory_limits.default_request_minimum | min $merged.memory.limit }}
          {{- $_ := set $merged.memory "request" $request }}
        {{- end }}

        {{- /* Update resource settings in-place */}}
        {{- range $key, $value := $merged }}
          {{- $_ := set $process $key $value }}
        {{- end }}
      {{- end }}

      {{- if not (index $jobs $ig_name $job_name "condition") }}
        {{- $_ := unset $ig $job_name }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _resources.expandDefaults $dict $key
+-----------------------------------------------------------------------------------------
| Make sure $dict[$key] either contains a fully expanded "$defaults" element or
| is a fully expanded "$defaults" element itself if $key is "$defaults".
|
| * Set $dict[$key] to an empty dict if it doesn't exist yet.
| * If $dict[$key] is a dict already:
|   - If $dict[$key]["$defaults"] doesn't exist, set it to a fully expanded $defaults tree.
|   - Else if $dict[$key]["$defaults"] is a scalar
|          then run expandDefaults($dict[$key], "$defaults") to expand it to a full tree.
| * Else
    - Set the $default["memory"]["limit"] to $dict[$key]
|   - If $key is the literal string "$default" set $dict[$key] to $default.
|   - Else set $dict[$key]["$defaults"] to $default.
==========================================================================================
*/}}
{{- define "_resources.expandDefaults" }}
  {{- $dict := index . 0 }}
  {{- $key := index . 1 }}

  {{- if not (hasKey $dict $key) }}
    {{- $_ := set $dict $key dict }}
  {{- end }}
  {{- $value := index $dict $key }}

  {{- $defaults := dict "cpu" (dict "limit" nil "request" nil) "memory" (dict "limit" nil "request" nil) }}

  {{- if kindIs "map" $value }}
    {{- if not (hasKey $value "$defaults") }}
      {{- $_ := set $value "$defaults" $defaults }}
    {{- else if not (kindIs "map" (index $value "$defaults")) }}
      {{- include "_resources.expandDefaults" (list $value "$defaults") }}
    {{- end }}
  {{- else }}
    {{- $_ := set $defaults.memory "limit" $value }}
    {{- if eq $key "$defaults" }}
      {{- $_ := set $dict $key $defaults }}
    {{- else }}
      {{- $_ := set $dict $key (dict "$defaults" $defaults) }}
    {{- end }}
  {{- end }}
{{- end }}
