{{ define "fail" }}
  {{- $root := index . 0 }}
  {{- $message := index . 1 }}
  {{- if $root.Values.fail_on_error }}
    {{- fail $message }}
  {{- else }}
    {{- printf "# %s" $message }}
  {{- end }}
{{- end }}
