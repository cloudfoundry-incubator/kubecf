def metadata_file_generator(name, file, operator_chart, visibility=None):
  native.genrule(
    name = name,
    srcs = [],
    outs = [file],
    cmd = "echo 'operatorChartUrl: \"{}\"' > $@".format(operator_chart),
    visibility = visibility,
  )
