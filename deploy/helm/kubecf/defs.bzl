"""
This Bazel extension contains rule definitions specific to KubeCF. Generic rules should be placed
under //rules.
"""

def metadata_file_generator(name, file, operator_chart, visibility=None):
  native.genrule(
    name = name,
    srcs = [],
    outs = [file],
    cmd = "echo 'operatorChartUrl: \"{}\"' > $@".format(operator_chart),
    visibility = visibility,
  )
