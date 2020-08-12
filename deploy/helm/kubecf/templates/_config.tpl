{{- /*
==========================================================================================
| _config.load $
+-----------------------------------------------------------------------------------------
| Initialize kubecf config object and load deployment manifest.
|
| This function creates $.kubecf in the root context and uses it as a container for global
| variables. Since templates can be rendered in arbitrary order, each template accessing
| $.kubecf must call "_config.load" first. This is done implicitly by the "_config.lookup"
| functions.
|
| The "cf-deployment.yml" file is loaded into $.kubecf.manifest.
|
| All "config/*" files as well as "values.yaml" are merged into a single $kubecf.config
| object in the following order: first all files that define a '$base_config' property,
| then all the files that don't, and finally $.Values. This makes it possible that
| add-on config files can overwrite settings defined in the base config.
|
| [The rest of this text pretends that $.kubecf is the current context]
|
| The .release.$defaults are saved in .defaults because they are used in templates
| to set the default and addon stemcells.
|
| After .config and .manifest have been setup, _stacks.update and _release.update are
| called to finalize the .config.stacks and .config.releases sub-trees. See their
| comments for more details.
|
| Finally all keys in the .deprecations object are evaluated with the _config.condition
| function, and if true, this function will fail with the corresponding deprecation
| message.
|
| The .config and .manifest objects can be searched by _config.lookup and
| _config.lookupManifest.
+-----------------------------------------------------------------------------------------
| For reference, these names are currently being used:
| * .config
| * .defaults
| * .manifest
| * .query
| * .retval
| * .required
==========================================================================================
*/}}
{{- define "_config.load" }}
  {{- if not $.kubecf }}
    {{- $_ := set $ "kubecf" dict }}
  {{- end }}
  {{- if not $.kubecf.config }}
    {{- $_ := set $.kubecf "manifest" (fromYaml ($.Files.Get "assets/cf-deployment.yml")) }}

    {{- $base_config := dict }}
    {{- $additional_config := dict }}
    {{- range $_, $bytes := $.Files.Glob "config/*" }}
      {{- $config := fromYaml (toString $bytes) }}
      {{- if index $config "$base_config" }}
        {{- $base_config = mergeOverwrite $base_config $config }}
      {{- else }}
        {{- $additional_config = mergeOverwrite $additional_config $config }}
      {{- end }}
    {{- end }}
    {{- $_ := set $.kubecf "config" (mergeOverwrite $base_config $additional_config $.Values) }}
    {{- $_ := set $.kubecf "required" false }}

    {{- $_ := set $.kubecf.config "defaults" (index $.kubecf.config.releases "$defaults") }}

    {{- $_ := include "_stacks.update" . }}
    {{- $_ := include "_releases.update" . }}

    {{- range $condition, $message := $.kubecf.config.deprecations }}
      {{- if eq "true" (include "_config.condition" (list $ $condition)) }}
        {{- fail $message }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _config.lookup (list $.kubecf $path)
+-----------------------------------------------------------------------------------------
| Look up a config setting in $.kubecf.config at $path.
|
| $path can be a '.' separated string of property names 'features.eirini.enabled', a
| list of names ("stacks" $stacks "releases"), or a combination of both. The '/' may
| also be used in place of the '.' for a more JSON-patch look.
|
| See comments on the _config._lookup implementation function for more details.
|
| This function calls _config.load to make sure the config object is initialized.
==========================================================================================
*/}}
{{- define "_config.lookup" }}
  {{- $_ := include "_config.load" (first .) }}
  {{- $kubecf := get (first .) "kubecf" }}
  {{- $_ := set $kubecf "query" (join "." (rest .) | replace "/" ".") }}
  {{- include "_config._lookup" (concat (list $kubecf $kubecf.config) (splitList "." $kubecf.query)) }}
  {{- $_ := set $kubecf "required" false }}
{{- end }}

{{- /*
==========================================================================================
| _config.lookupRequired (list $.kubecf $path)
+-----------------------------------------------------------------------------------------
| This function is currently unused and works identical to _config.lookup.
+-----------------------------------------------------------------------------------------
| Not yet implemented:
|
| This function was supposed to be identical to _config.lookup, except it would fail
| with a sensible error message if the $path did not exist. It may no longer be needed
| now that we have JSON schema validation.
==========================================================================================
*/}}
{{- define "kubecf.configRequired" }}
  {{- $kubecf := get (first .) "kubecf" }}
  {{- $_ := set $kubecf "required" true }}
  {{- include "_config.lookup" . }}
{{- end }}

{{- /*
==========================================================================================
| _config.lookupManifest (list $.kubecf $path)
+-----------------------------------------------------------------------------------------
| The same function as _config.lookup, except it searches $kubecf.manifest instead.
==========================================================================================
*/}}
{{- define "_config.lookupManifest" }}
  {{- $_ := include "_config.load" (first .) }}
  {{- $kubecf := get (first .) "kubecf" }}
  {{- $_ := set $kubecf "query" (join "." (rest .) | replace "/" ".") }}
  {{- include "_config._lookup" (concat (list $kubecf $kubecf.manifest) (splitList "." $kubecf.query)) }}
  {{- $_ := set $kubecf "required" false }}
{{- end }}

{{- /*
==========================================================================================
| _config._lookup (list $.kubecf $context $path)
+-----------------------------------------------------------------------------------------
| Internal implementation of "_config.lookup" and "_config.lookupManifest".
|
| Lookup $path under $context and return either the value found, or the empty string.
|
| $context is either is an object (or array). It normally starts out as $.kubecf.config
| or $.kubecf.manifest, but moves down the tree as _lookup calls itself recursively.
|
| $path is a list of properties to look up successively, e.g. ("stacks" $stack "releases").
|
| When the found value is `nil`, we still return the empty string and not a stringified
| nil (which would be "<no data>"), because helm prints it as an empty string, but
| otherwise treats as a non-empty string for all other purposes.
|
| $kubecf.retval is also set to the found entry in case the caller needs an object and
| not just a string. This can also be used to disambiguate between nil and the empty
| string (which can mean: not found).
|
| When $context is an array, then _lookup will look for an array element that has a "name"
| property matching the first element of $path.
|
| Example: Looking for "instance_groups.api.jobs.cloud_controller_ng" in $.kubecf.manifest
| is equivalent to the "/instance_groups/name=api/jobs/name=cloud_controller_ng" path in
| JSON-patch.
|
| If the first element of $path for a list lookup contains a '=', the left side of specifies
| the property to look for, in case it is not "name", e.g. "foo/os=linux/description".
+-----------------------------------------------------------------------------------------
| Not implemented:
|
| When the full $path cannot be found, and the $.kubecf.required variable is true, then
| _lookup should throw an error instead of returning an empty string. It could use
| $.kubecf.query to provide a helpful error message. With the introduction of a
| validation schema, this may no longer be required.
==========================================================================================
*/}}
{{- define "_config._lookup" }}
  {{- $kubecf := index . 0 }}
  {{- $context := index . 1 }}
  {{- $path := slice . 2 }}
  {{- $key := (first $path) }}

  {{- if kindIs "slice" $context }}
    {{- $name := "name" }}
    {{- if contains "=" $key }}
      {{- $keyList := splitList "=" $key }}
      {{- $name = first $keyList }}
      {{- $key = index $keyList 1 }}
    {{- end }}
    {{- $_ := set $kubecf "retval" nil }}
    {{- range $context }}
      {{- if eq (index . $name) $key }}
        {{- $_ := set $kubecf "retval" . }}
      {{- end }}
    {{- end }}
  {{- else }}
    {{- $_ := set $kubecf "retval" (index $context $key) }}
  {{- end }}

  {{- if $kubecf.retval }}
    {{- if gt (len $path) 1 }}
      {{- include "_config._lookup" (concat (list $kubecf $kubecf.retval) (rest $path)) }}
    {{- else }}
      {{- $kubecf.retval }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _config.condition (list $ $condition)
+-----------------------------------------------------------------------------------------
| Evaluates $condition and returns either the string "true" or the string "false"
| (without the quotes, of course).
|
| - A nil (missing) condition is always true.
|
| - A boolean condition is the value of the $condition itself.
|
| - Otherwise $condition must be a string. All spaces will be removed first.
|
| - The string can be a list of "||" separated OR terms. The condition is true
|   if any of the terms are true.
|
| - An OR term can be a list of "&&" separated AND terms. The OR term is true
|   if all of the AND terms are true.
|
| - An AND term is either the string "true" or "false", or it will be evaluated
|   by looking up it's value in $.kubecf.config.
|
| - An AND term may be prefixed by "!" in which case its value is negated.
|
| - An AND term may also be a condition expression enclosed in parenthesis.
|
| - None of the terms can be an empty string.
|
| Example: "!features.foo.enabled && (features.bar.enabled || features.baz.enabled)"
|
| Usage examples: This function is used to evaluate the keys of the
| "deprecation" hash earlier in this file, and the "release.condition" values
| in assets/operations/releases.yaml.
==========================================================================================
*/}}
{{- define "_config.condition" }}
  {{- $root := index . 0 }}
  {{- $condition := index . 1 }}

  {{- if kindIs "invalid" $condition }}
    {{- /* The absence of a condition (nil) is unconditionally true */}}
    {{- $condition = true }}
  {{- end }}

  {{- if kindIs "bool" $condition }}
    {{- ternary "true" "false" $condition }}

  {{- else }}
    {{- /* Count the number of left parenthesis to determine the number of groups */}}
    {{- range $_ := until (sub (len (splitList "(" $condition)) 1 | int) }}
      {{- /* Find left inner-most group, evaluate it, and replace the expression with the value */}}
      {{- $group := regexFind "\\([^\\)]+\\)" $condition }}
      {{- /* There may be fewer groups than left parens if some groups turn out to be identical */}}
      {{- /* E.g. "((to.be) || !(to.be))" will collapse to "(true || !true)" after the 1st iteration */}}
      {{- if $group }}
        {{- $value := include "_config.condition" (list $root ($group | trimPrefix "(" | trimSuffix ")")) }}
        {{- $condition = replace $group $value $condition }}
      {{- end }}
    {{- end }}

    {{- /* Evaluate the remaining expression based on operator precedence: NOT (highest), AND, OR (lowest) */}}
    {{- $or_value := false }}
    {{- range $or_term := splitList "||" (nospace $condition) }}
      {{- $and_value := true }}
      {{- range $and_term := splitList "&&" $or_term }}
        {{- $term := trimPrefix "!" $and_term }}
        {{- /* The term is either literally "true" or "false", or must be looked up */}}
        {{- $value := true }}
        {{- if ne $term "true" }}
          {{- if eq $term "false" }}
            {{- $value = false }}
          {{- else }}
            {{- $value = include "_config.lookup" (list $root $term) }}
          {{- end }}
        {{- end }}
        {{- if hasPrefix "!" $and_term }}
          {{- $value = not $value }}
        {{- end }}
        {{- $and_value = and $and_value $value }}
      {{- end }}
      {{- $or_value = or $or_value $and_value }}
    {{- end }}
    {{- /* "ternary" requires a real bool for the third argument */}}
    {{- ternary "false" "true" (not $or_value) }}
  {{- end }}
{{- end }}
