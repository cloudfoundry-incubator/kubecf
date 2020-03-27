"""
This Bazel extension contains the set of rule definitions to deal with generic IO.
"""

def _print_files_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = "cat {}".format(" ".join([src.short_path for src in ctx.files.srcs]))
    ctx.actions.write(executable, contents, is_executable = True)
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = ctx.files.srcs),
    )]

# print_files calls cat on all srcs in order, printing the contents to the terminal.
print_files = rule(
    implementation = _print_files_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
    },
    executable = True,
)
