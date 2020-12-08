{{- /*
==========================================================================================
| _credhub.update $
+-----------------------------------------------------------------------------------------
| kubecf credhub customization
| - disable consumption of `postgres` bosh-link. It is optional, and we do not
|   wish to reconfigure credhub when autoscaler comes online or is switched off.
|   I.e. autoscaler provides a postgres link, and we we wish to ignore it.
==========================================================================================
*/}}
{{- define "_credhub.update" }}
{{- $_ := include "_config.lookupManifest" (list $ "instance_groups/name=credhub/jobs/name=credhub") }}
{{- if $.kubecf.retval }}
{{- $_ := set $.kubecf.retval "consumes" (fromYaml "postgres: null") }}
{{- end }}
{{- end }}
