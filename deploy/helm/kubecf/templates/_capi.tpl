{{- /*
==========================================================================================
| _capi.setProperty $property $value
+-----------------------------------------------------------------------------------------
| There are 4 CAPI jobs that all share the same cloud_controller_ng specs file,
| and therefore potentially all use the same "cc" properties. This template will
| set a property in all of the jobs, so there is a single location to keep track
| of instance groups these jobs run in.
|
| $property can be a JSON-patch path fragment, e.g. "diego/foo" to set the
| "cc.diego.foo" property.
==========================================================================================
*/}}
{{- define "_capi.setProperty" }}
  {{- $property := index . 0 }}
  {{- $value := index . 1 }}

  {{- $ig := dict }}
  {{- $_ := set $ig "cloud_controller_ng"     "api"       }}
  {{- $_ := set $ig "cloud_controller_worker" "cc-worker" }}
  {{- $_ := set $ig "cloud_controller_clock"  "scheduler" }}
  {{- $_ := set $ig "cc_deployment_updater"   "scheduler" }}
  {{- /* XXX cc_route_syncer is not in cf-deployment; see CF-K8s-Networking */}}
  {{- /* $_ := set $ig "cc_route_syncer" "???" */}}

  {{- range $job := keys $ig }}
- type: replace
  path: /instance_groups/name={{ get $ig $job }}/jobs/name={{ $job }}?/properties/cc/{{ $property }}
  value: {{ $value | toJson }}
  {{- end }}
{{- end }}
