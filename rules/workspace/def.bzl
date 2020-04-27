"""An extension for workspace rules."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//:dependencies.bzl", "dependencies")

def _workspace_dependencies_impl(ctx):
    platform = ctx.os.name if ctx.os.name != "mac os x" else "darwin"
    for dependency in dependencies:
        ctx.download(
            executable = True,
            output = dependency["name"],
            sha256 = dependency["sha256"][platform],
            url = dependency["url"][platform].format(version = dependency["version"]),
        )

    ctx.file("BUILD.bazel", 'exports_files(glob(["**/*"]))\n')

_workspace_dependencies = repository_rule(_workspace_dependencies_impl)

_WORKSPACE_DEPENDENCIES_REPOSITORY_NAME = "workspace_dependencies"

def workspace_dependencies():
    """A macro for wrapping the workspace_dependencies repository rule with a hardcoded name.

    The workspace_dependencies repository rule should be called before any of the other rules in
    this Bazel extension.
    Hardcoding the target name is useful for consuming it internally. The targets produced by this
    rule are only used within the workspace rules.
    """
    _workspace_dependencies(
        name = _WORKSPACE_DEPENDENCIES_REPOSITORY_NAME,
    )

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
    _workspace_status_impl,
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
            default = "@{}//:jq".format(_WORKSPACE_DEPENDENCIES_REPOSITORY_NAME),
            executable = True,
        ),
    },
)

def _yaml_loader(ctx):
    # Check if the output file name has the .bzl extension.
    out_ext = ctx.attr.out[len(ctx.attr.out)-4:]
    if out_ext != ".bzl":
        fail("Expected output file ({out}) to have .bzl extension".format(out = ctx.attr.out))

    # Get the yq binary path.
    yq = ctx.path(ctx.attr._yq)

    # Get the YAML src absolute path and convert it to JSON.
    src = ctx.path(ctx.attr.src)
    res = ctx.execute([yq, "r", "--tojson", src])
    if res.return_code != 0:
        fail(res.stderr)

    ctx.file("file.json", res.stdout)

    # Convert the JSON file to the Starlark extension.
    converter = ctx.path(ctx.attr._converter)
    res = ctx.execute([_python3(ctx), converter, "file.json"])
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
        "_yq": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@{}//:yq".format(_WORKSPACE_DEPENDENCIES_REPOSITORY_NAME),
            executable = True,
        ),
        "_converter": attr.label(
            allow_single_file = True,
            default = "//:json_bzl_converter.py",
        ),
    },
)

def _python3(repository_ctx):
    """A helper function to get the Python 3 system interpreter if available. Otherwise, it fails.
    """
    for option in ["python", "python3"]:
        python = repository_ctx.which(option)
        if python != None:
            res = repository_ctx.execute([python, "--version"])
            if res.return_code != 0:
                fail(res.stderr)
            version = res.stdout.strip() if res.stdout.strip() != "" else res.stderr.strip()
            version = version.split(" ")
            if len(version) != 2:
                fail("Unable to parse Python output version: {}".format(version))
            version = version[1]
            major_version = version.split(".")[0]
            if int(major_version) == 3:
                return python
    fail("Python 3 is required")
