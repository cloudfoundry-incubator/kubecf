{{- /*
==========================================================================================
| _config.load $
+-----------------------------------------------------------------------------------------
| Merges all kubecf config files into $.Values and loads the deployment manifest.
|
| This function creates $.Values.kubecf and uses it as a container for global variables.
| Since templates can be rendered in arbitrary order, each template accessing
| $.Values must call "_config.load" first. This is done implicitly by the "_config.lookup"
| functions.
|
| The "cf-deployment.yml" file is loaded into $.kubecf.manifest.
|
| All "config/*" files are merged into $.Values in alphabetical sort sequence, without
| overwriting values that already exist. The base config files all start with lowercase
| letters, so any add-ons that want to overwrite a base config setting should use an
| uppercase config filename, to be merged first. Obviously no config file can overwrite
| an explict user choice from $.Values.
|
| The $.Values.release.$defaults are saved in $.kubecf.defaults because they are used
| in templates to set the default and addon stemcells.
|
| After $.Values and $.kubecf.manifest have been setup, _stacks.update and _release.update
| are called to finalize the $.Values.stacks and $.Values.releases sub-trees. See their
| comments for more details.
|
| Finally all keys in the $.Values.unsupported object are evaluated with the _config.condition
| function, and if true, this function will fail with the corresponding error message.
|
| The $.Values and $.kubecf.manifest objects can be searched by _config.lookup and
| _config.lookupManifest, respectively.
+-----------------------------------------------------------------------------------------
| For reference, these names are currently being used:
| * $.Values
| * $.Values.defaults
| * $.kubecf.manifest
| * $.kubecf.retval
==========================================================================================
*/}}
{{- define "_config.load" }}
  {{- if not $.kubecf }}
    {{- $_ := set $ "kubecf" dict }}
  {{- end }}
  {{- if not $.kubecf.manifest }}
    {{- $_ := set $.kubecf "manifest" (fromYaml ($.Files.Get "assets/cf-deployment.yml")) }}

    {{- $configs := dict }}
    {{- range $name, $bytes := $.Files.Glob "config/*" }}
      {{- $config := $bytes | toString | fromYaml }}
      {{- if hasKey $config "Error" }}
        {{- include "_config.fail" (printf "Config file %q is invalid:\n%s" $name $config.Error) }}
      {{- end }}
      {{- $_ := set $configs $name $config }}
    {{- end }}
    {{- range $name := keys $configs | sortAlpha }}
      {{- $_ := merge $.Values (get $configs $name) }}
    {{- end }}

    {{- $_ := set $.Values "defaults" (index $.Values.releases "$defaults") }}

    {{- include "_features.update" . }}
    {{- include "_stacks.update" . }}
    {{- include "_releases.update" . }}
    {{- include "_jobs.update" . }}
    {{- include "_resources.update" . }}

    {{- range $condition, $message := $.Values.unsupported }}
      {{- if eq "true" (include "_config.condition" (list $ $condition)) }}
        {{- include "_config.fail" $message }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{- /*
==========================================================================================
| _config.fail $message
+-----------------------------------------------------------------------------------------
| Fails with $message but also with additional newlines and a separator upfront
| to make it distinct from the mix of stack trace and YAML data preceeding it.
==========================================================================================
*/}}
{{- define "_config.fail" }}
  {{- fail (printf "\n\n\n\n============================\n\n%s" .) }}
{{- end }}

{- /*
==========================================================================================
| _config.lookup (list $ $path)
+-----------------------------------------------------------------------------------------
| Look up a config setting in $.Values at $path.
|
| $path can be a '.' separated string of property names 'features.eirini.enabled', a
| list of names ("stacks" $stacks "releases"), or a combination of both. The separator
| '/' may also be used in place of the '.' for a more JSON-patch look.
|
| See comments on the _config._lookup implementation function for more details.
==========================================================================================
*/}}
{{- define "_config.lookup" }}
  {{- $root := first . }}
  {{- $query := join "." (rest .) | replace "/" "." }}
  {{- include "_config._lookup" (concat (list $root.kubecf $root.Values) (splitList "." $query)) }}
{{- end }}

{{- /*
==========================================================================================
| _config.lookupManifest (list $ $path)
+-----------------------------------------------------------------------------------------
| The same function as _config.lookup, except it searches $.kubecf.manifest instead.
==========================================================================================
*/}}
{{- define "_config.lookupManifest" }}
  {{- $kubecf := get (first .) "kubecf" }}
  {{- $query := join "." (rest .) | replace "/" "." }}
  {{- include "_config._lookup" (concat (list $kubecf $kubecf.manifest) (splitList "." $query)) }}
{{- end }}

{{- /*
==========================================================================================
| _config._lookup (list $.kubecf $context $path)
+-----------------------------------------------------------------------------------------
| Internal implementation of "_config.lookup" and "_config.lookupManifest".
|
| Lookup $path under $context and return either the value found, or the empty string.
| Maps and slices are returned in JSON format; nil is returned as the empty string.
|
| $context is either an object or an array. It normally starts out as $.Values
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
| property matching the first element of $path. If there are multiple matching array
| elements, _lookup will pick the last one it finds.
|
| Example: Looking for "instance_groups.api.jobs.cloud_controller_ng" in $.kubecf.manifest
| is equivalent to the "/instance_groups/name=api/jobs/name=cloud_controller_ng" path in
| JSON-patch.
|
| If the first element of $path for a list lookup contains a '=', the left side of specifies
| the property to look for, in case it is not "name", e.g. "foo/os=linux/description".
==========================================================================================
*/}}
{{- define "_config._lookup" }}
  {{- $kubecf := index . 0 }}
  {{- $context := index . 1 }}
  {{- $path := slice . 2 }}
  {{- $key := first $path }}

  {{- if kindIs "slice" $context }}
    {{- $name := "name" }}
    {{- if contains "=" $key }}
      {{- $keyList := splitn "=" 2 $key }}
      {{- $name = $keyList._0 }}
      {{- $key = $keyList._1 }}
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
      {{- if or (kindIs "map" $kubecf.retval) (kindIs "slice" $kubecf.retval) }}
        {{- $kubecf.retval | toJson }}
      {{- else }}
        {{- $kubecf.retval }}
      {{- end }}
    {{- end }}
  {{- else }}
    {{- if gt (len $path) 1 }}
      {{- $_ := set $kubecf "retval" nil }}
    {{- end }}
    {{- /* Return YAML compatible string versions of "zero" values; empty string for all other kinds */}}
    {{- $zero := dict "bool" "false" "int" 0 "int64" 0 "float64" 0 "map" "{}" "slice" "[]" }}
    {{- get $zero (kindOf $kubecf.retval) }}
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
|   by looking up its value in $.Values.
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
| "unsupported" hash earlier in this file, and the "release.condition" values
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
    {{- range $_ := splitList "(" $condition | len | add -1 | int | until }}
      {{- /* Find left inner-most group, evaluate it, and replace the expression with the value */}}
      {{- $group := regexFind "\\([^\\)]+\\)" $condition }}
      {{- /* There may be fewer groups than left parens if some groups turn out to be identical */}}
      {{- /* E.g. "((to.be) || !(to.be))" will collapse to "(true || !true)" after the 1st iteration */}}
      {{- if $group }}
        {{- $inner_expr := $group | trimPrefix "(" | trimSuffix ")" }}
        {{- $value := include "_config.condition" (list $root $inner_expr) }}
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
        {{- if eq $term "true" }}
          {{- /* $value is already true */}}
        {{- else if eq $term "false" }}
          {{- $value = false }}
        {{- else }}
          {{- $_ := include "_config.lookup" (list $root $term) }}
          {{- $value = $root.kubecf.retval }}
        {{- end }}
        {{- if hasPrefix "!" $and_term }}
          {{- $value = not $value }}
        {{- end }}
        {{- $and_value = and $and_value $value }}
      {{- end }}
      {{- $or_value = or $or_value $and_value }}
    {{- end }}
    {{- /* Double-negation turns $or_value into a true boolean, as required by "ternary" */}}
    {{- ternary "true" "false" ($or_value | not | not) }}
  {{- end }}
{{- end }}

{{- /*
==========================================================================================
| _config.property (list $ $ig $job $property)
+-----------------------------------------------------------------------------------------
| Lookup a property value, first by checking for an override from $.Values.properties,
| falling back to settings from the manifest. The helm chart has no access to the defaults
| from the job's spec file, so the defaults need to be defined in a bundled config file
| if the property is required, but not set in cf-deployment.
==========================================================================================
*/}}
{{- define "_config.property" }}
  {{- $root := index . 0 }}
  {{- $ig := index . 1 }}
  {{- $job := index . 2 }}
  {{- $property := index . 3 }}

  {{- /* Lookup property in $.Values */}}
  {{- $retval := include "_config.lookup" (list $root "properties" $ig $job $property) }}

  {{- /* Fallback to manifest if there was no override */}}
  {{- if kindIs "invalid" $root.kubecf.retval }}
    {{- $query := printf "instance_groups/name=%s/jobs/name=%s/properties/%s" $ig $job $property }}
    {{- $retval = include "_config.lookupManifest" (list $root $query) }}
  {{- end }}

  {{- $retval }}
{{- end }}
