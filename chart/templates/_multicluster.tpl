{{- /*
==========================================================================================
| _multicluster.update $
+-----------------------------------------------------------------------------------------
| Remove property settings for instance groups that will not be instantiated.
==========================================================================================
*/}}
{{- define "_multicluster.update" }}
  {{- if $.Values.features.multiple_cluster_mode.control_plane.enabled }}
    {{- $_ := unset $.Values.properties "diego-cell" }}
  {{- end }}
  {{- if $.Values.features.multiple_cluster_mode.cell_segment.enabled }}
    {{- $_ := unset $.Values.properties "acceptance-tests" }}
    {{- $_ := unset $.Values.properties "api" }}
    {{- $_ := unset $.Values.properties "auctioneer" }}
    {{- $_ := unset $.Values.properties "brain-tests" }}
    {{- $_ := unset $.Values.properties "cc-worker" }}
    {{- $_ := unset $.Values.properties "diego-api" }}
    {{- $_ := unset $.Values.properties "doppler" }}
    {{- $_ := unset $.Values.properties "log-api" }}
    {{- $_ := unset $.Values.properties "log-cache" }}
    {{- $_ := unset $.Values.properties "nats" }}
    {{- $_ := unset $.Values.properties "rotate-cc-database-key" }}
    {{- $_ := unset $.Values.properties "router" }}
    {{- $_ := unset $.Values.properties "scheduler" }}
    {{- $_ := unset $.Values.properties "singleton-blobstore" }}
    {{- $_ := unset $.Values.properties "smoke-tests" }}
    {{- $_ := unset $.Values.properties "sync-integration-tests" }}
    {{- $_ := unset $.Values.properties "uaa" }}
  {{- end }}
{{- end }}
