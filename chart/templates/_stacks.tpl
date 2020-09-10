{{- /*
==========================================================================================
| _stacks.update $
+-----------------------------------------------------------------------------------------
| For each $STACK:
|
| * Update the stemcell and url of each release from the "$defaults"
|
| * Sets stacks.$STACK.enabled depending on install_stacks
| * Sets stacks.$STACK.install_buildpacks to [prepend, list, append]
| * Sets stacks.$STACK.buildpack to map buildpack short names to releases
|
| For each $RELEASE (in each $STACK):
|
| * Sets stacks.$STACK.releases.$RELEASE.stack to $STACK
| * Sets stacks.$STACK.releases.$RELEASE.enable to true unless the release has
|   a "buildpack" property and its value is not in the stack's install_buildpacks
|
| Finally
|
| * Merges stacks.$STACK.releases into releases
| * Validate that all install_stacks and install_buildpacks are defined
==========================================================================================
*/}}
{{- define "_stacks.update" }}
  {{- /* +---------------------------------------------------------------------------+ */}}
  {{- /* | Setup the cflinux stack from the configuration in the deployment manifest | */}}
  {{- /* +---------------------------------------------------------------------------+ */}}

  {{- $_ := include "_config.lookupManifest" (list $ "instance_groups/name=api/jobs/name=cloud_controller_ng/properties.cc.stacks") }}
  {{- $cc_stacks := $.kubecf.retval }}

  {{- if ne (len $cc_stacks) 1 }}
    {{- include "_config.fail" "cf-deployment defines more than one stack (or none)" }}
  {{- end }}
  {{- $cc_stack := index $cc_stacks 0 }}

  {{- /* *** Verify that "config.$cc_stack" exists (so the name hasn't changed in the manifest) *** */}}
  {{- $_ := include "_config.lookup" (list $ "stacks" $cc_stack.name) }}
  {{- $stack := $.kubecf.retval }}
  {{- if not $stack }}
    {{- include "_config.fail" (printf "cf-deployment stack %q not configured in kubecf" $cc_stack.name) }}
  {{- end }}

  {{- /* *** Copy stack "description" from manifest *** */}}
  {{- $_ := set $stack "description" $cc_stack.description }}

  {{- /* *** Make sure "$stack.releases" exists and has an entry for "$cc_stack.name" (the rootfs) *** */}}
  {{- if not $stack.releases }}
    {{- $_ := set $stack "releases" dict }}
  {{- end }}
  {{- if not (index $stack.releases $cc_stack.name) }}
    {{- $_ := set $stack.releases $cc_stack.name dict }}
  {{- end }}

  {{- /* *** Create "$stack.install_buildpacks" and "$stack.releases" from the "api" buildpack jobs *** */}}
  {{- $_ := set $stack "install_buildpacks" list }}

  {{- $_ := include "_config.lookupManifest" (list $ "instance_groups/name=api/jobs") }}
  {{- range $job := $.kubecf.retval }}
    {{- if hasSuffix "-buildpack" $job.release }}
      {{- $buildpack_shortname := trimSuffix "-buildpack" $job.release }}
      {{- $_ := set $stack "install_buildpacks" (append $stack.install_buildpacks $buildpack_shortname) }}
      {{- /* Make sure an entry for the release exists; versions will be filled in by _releases.update */}}
      {{- if not (index $stack.releases $job.release) }}
        {{- $_ := set $stack.releases $job.release dict }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* +----------------------------------------------------------------------------------------------+ */}}
  {{- /* | Setup the additional stacks in .config.stacks and merge their releases into .config.releases | */}}
  {{- /* +----------------------------------------------------------------------------------------------+ */}}

  {{- $_ := include "_config.lookup" (list $ "stacks") }}
  {{- range $stack_name, $stack := $.kubecf.retval }}
    {{- $_ := set $stack "enabled" (has $stack_name $.Values.install_stacks) }}

    {{- /* *** Mark all releases in the stack as data-only *** */}}
    {{- if not (hasKey $stack.releases "$defaults") }}
      {{- $_ := set $stack.releases "$defaults" dict }}
    {{- end }}
    {{- $_ := set (index $stack.releases "$defaults") "data-only" true }}

    {{- /* *** Update all releases with defaults from stack.releases.$defaults *** */}}
    {{- $_ := include "_releases.applyDefaults" $stack.releases }}

    {{- /* *** Combine install_buildpacks with prepend and append lists *** */}}
    {{- $install_buildpacks := list }}
    {{- if $stack.install_buildpacks_prepend }}
      {{- $install_buildpacks = $stack.install_buildpacks_prepend }}
    {{- end }}
    {{- if $stack.install_buildpacks }}
      {{- $install_buildpacks = concat $install_buildpacks $stack.install_buildpacks }}
    {{- end }}
    {{- if $stack.install_buildpacks_append }}
      {{- $install_buildpacks = concat $install_buildpacks $stack.install_buildpacks_append }}
    {{- end }}
    {{- $_ := set $stack "install_buildpacks" $install_buildpacks }}

    {{- /* create $stack.buildpacks mapping from buildpack shortname to release name */}}
    {{- $_ := set $stack "buildpacks" dict }}

    {{- $release_prefix := printf "%s-" (default "" $stack.release_prefix) }}
    {{- $release_suffix := printf "-%s" (default "buildpack" $stack.release_suffix) }}
    {{- range $release_name, $release := $stack.releases }}
      {{- $_ := set $release "condition" $stack.enabled }}

      {{- /* *** Set buildpack shortname from release name (unless already set, or rootfs) *** */}}
      {{- if and (ne $release_name $stack_name) (not $release.buildpack) }}
        {{- $shortname := $release_name | trimSuffix $release_suffix | trimPrefix $release_prefix }}
        {{- $_ := set $release "buildpack" $shortname }}
      {{- end }}

      {{- if $release.buildpack }}
        {{- if has $release.buildpack $install_buildpacks }}
          {{- /* Map the buildpack shortname to the release name */}}
          {{- $_ := set $stack.buildpacks $release.buildpack $release_name }}
        {{- else }}
          {{- $_ := set $release "condition" false }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- $_ := set $.Values "releases" (mergeOverwrite $.Values.releases $stack.releases) }}
  {{- end }}

  {{- /* *** Make sure all requested stacks and their buildpacks are defined *** */}}
  {{- range $stack_name := $.Values.install_stacks }}
    {{- if not (include "_config.lookup" (list $ "stacks" $stack_name)) }}
      {{- include "_config.fail" (printf "Stack %s is not defined" $stack_name) }}
    {{- end }}
    {{- $stack := $.kubecf.retval }}
    {{- if not (include "_config.lookup" (list $ "releases" $stack_name)) }}
      {{- include "_config.fail" (printf "No rootfs release found for stack %s" $stack_name) }}
    {{- end }}
    {{- range $buildpack_name := $stack.install_buildpacks }}
      {{- if not (include "_config.lookup" (list $ "stacks" $stack_name "buildpacks" $buildpack_name)) }}
        {{- include "_config.fail" (printf "No release found for buildpack %s (used by stack %s)" $buildpack_name $stack_name) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
