{{- /*
==========================================================================================
| _capi.setProperty $property [$value]
+-----------------------------------------------------------------------------------------
| There are 4 CAPI jobs that all share the same cloud_controller_ng specs file,
| and therefore potentially all use the same "cc" properties. This template will
| set a property in all of the jobs, so there is a single location to keep track
| of instance groups these jobs run in.
|
| If the property starts with "buildpacks" then it will only be set in the cloud
| controller jobs (ng, worker, clock), because the other job(s) don't use/define
| these properties.
|
| $property can use dotted path notation to specify nested properties,
| e.g. "diego.foo" to set the "cc.diego.foo" property.
|
| If the $value is omitted, the property is removed from the manifest.
==========================================================================================
*/}}
{{- define "_capi.setProperty" }}
  {{- $params := . }}
  {{- $property := index $params 0 }}

  {{- $ig := dict }}
  {{- $_ := set $ig "cloud_controller_ng"     "api"       }}
  {{- $_ := set $ig "cloud_controller_worker" "cc-worker" }}
  {{- $_ := set $ig "cloud_controller_clock"  "scheduler" }}

  {{- /* The buildpacks properties are only defined for the ng/worker/clock jobs */}}
  {{- if not (hasPrefix "buildpacks" $property) }}
    {{- $_ := set $ig "cc_deployment_updater"   "scheduler" }}
    {{- /* XXX cc_route_syncer is not in cf-deployment; see CF-K8s-Networking */}}
    {{- /* $_ := set $ig "cc_route_syncer" "???" */}}
  {{- end }}

  {{- range $job, $instance_group := $ig }}
- path: /instance_groups/name={{ $instance_group }}/jobs/name={{ $job }}?/properties/cc/{{ $property | replace "." "/" }}
    {{- if lt (len $params) 2 }}
  type: remove
    {{- else }}
  type: replace
  value: {{ index $params 1 | toJson }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _capi.removeProperty $property
+-----------------------------------------------------------------------------------------
| Alias for _capi.setProperty, just to make it clearer at the call site that this
| is removing a property and not setting a value.
==========================================================================================
*/}}
{{- define "_capi.removeProperty" }}
  {{- include "_capi.setProperty" (list .) }}
{{- end }}
