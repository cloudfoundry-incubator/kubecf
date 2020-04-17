load("@bazel_skylib//lib:paths.bzl", "paths")

def _workspace_status_impl(ctx):
    info_file_json = _convert_status(ctx, ctx.info_file)
    version_file_json= _convert_status(ctx, ctx.version_file)

    status_merger = ctx.actions.declare_file("status_merger.sh")
    workspace_status = ctx.actions.declare_file("workspace_status.json")
    ctx.actions.expand_template(
        is_executable = True,
        output = status_merger,
        substitutions = {
            "{info_file}": info_file_json.path,
            "{version_file}": version_file_json.path,
            "{workspace_status}": workspace_status.path,
            "{jq}": ctx.executable._jq.path,
        },
        template = ctx.file._status_merger_tmpl,
    )
    ctx.actions.run(
        executable = status_merger,
        inputs = [
            info_file_json,
            version_file_json,
        ],
        outputs = [workspace_status],
        tools = [ctx.executable._jq],
    )

    return [DefaultInfo(files = depset([workspace_status]))]

def _convert_status(ctx, status_file):
    status_file_basename = paths.basename(status_file.path)
    status_file_json_name = paths.replace_extension(status_file_basename, ".json")
    status_file_json = ctx.actions.declare_file(status_file_json_name)
    status_converter = ctx.actions.declare_file("{}_converter.sh".format(status_file_basename))
    ctx.actions.expand_template(
        is_executable = True,
        output = status_converter,
        substitutions = {
            "{input}": status_file.path,
            "{output}": status_file_json.path,
            "{jq}": ctx.executable._jq.path,
        },
        template = ctx.file._status_converter_tmpl,
    )
    ctx.actions.run(
        executable = status_converter,
        inputs = [status_file],
        outputs = [status_file_json],
        tools = [ctx.executable._jq],
    )
    return status_file_json

workspace_status = rule(
    implementation = _workspace_status_impl,
    attrs = {
        "_status_converter_tmpl": attr.label(
            allow_single_file = True,
            default = "//:status_converter.tmpl.sh",
        ),
        "_status_merger_tmpl": attr.label(
            allow_single_file = True,
            default = "//:status_merger.tmpl.sh",
        ),
        "_jq": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@jq//:jq",
            executable = True,
        ),
    },
)

def _yaml_loader(ctx):
    # Check if the output file name has the .bzl extension.
    out_ext = ctx.attr.out[len(ctx.attr.out)-4:]
    if out_ext != ".bzl":
        fail("Expected output file ({out}) to have .bzl extension".format(out = ctx.attr.out))

    # Get the src absolute path and write the Python script that generates the output .bzl file.
    src = ctx.path(ctx.attr.src)
    script = """
import yaml

with open("{src}", "r") as stream:
    for key, value in yaml.safe_load(stream).items():
        print(key + " = " + str(value))
""".format(src = src)
    ctx.file("script.py", script)

    # Execute the script.
    res = ctx.execute(["python", "script.py"])
    if res.return_code != 0:
        fail(res.stderr)

    # Write the .bzl file with the YAML contents converted.
    ctx.file(ctx.attr.out, res.stdout)

    # An empty BUILD.bazel is only needed to indicate it's a Bazel package.
    ctx.file("BUILD.bazel", "")

yaml_loader = repository_rule(
    _yaml_loader,
    doc = "A repository rule to load a YAML file into a Starlark dictionary",
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            doc = "The YAML file to be loaded into a Starlark dictionary",
            mandatory = True,
        ),
        "out": attr.string(
            doc = "The output file name",
            mandatory = True,
        ),
    },
)
