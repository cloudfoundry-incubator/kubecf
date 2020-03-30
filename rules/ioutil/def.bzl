"""
This Bazel extension contains the set of rule definitions to deal with generic IO.
"""

def _print_files_impl(ctx):
    """
    An executable rule to print to the terminal the files passed via the 'srcs' property.
    """
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = "cat {}".format(" ".join([src.short_path for src in ctx.files.srcs]))
    ctx.actions.write(executable, contents, is_executable = True)
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = ctx.files.srcs),
    )]

print_files = rule(
    implementation = _print_files_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The list of files to be printed to the terminal",
        ),
    },
    executable = True,
)
