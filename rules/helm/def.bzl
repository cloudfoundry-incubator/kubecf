def _package_impl(ctx):
    output_filename = "{}-{}.tgz".format(ctx.attr.chart_name, ctx.attr.chart_version)
    output_tgz = ctx.actions.declare_file(output_filename)
    outputs = [output_tgz]
    ctx.actions.run(
        inputs = [] + ctx.files.srcs + ctx.files.tars + ctx.files.generated,
        outputs = outputs,
        tools = [ctx.executable._helm],
        progress_message = "Generating Helm package archive {}".format(output_filename),
        executable = ctx.executable._script,
        env = {
            "PACKAGE_DIR": ctx.attr.package_dir,
            # TODO(f0rmiga): Figure out a way of working with paths that contain spaces.
            "TARS": " ".join([f.path for f in ctx.files.tars]),
            # TODO(mudler): Support also nested folders and paths with spaces
            "GENERATED": " ".join([f.path for f in ctx.files.generated]),
            "HELM": ctx.executable._helm.path,
            "CHART_VERSION": ctx.attr.chart_version,
            "APP_VERSION": ctx.attr.app_version,
            "OUTPUT_FILENAME": output_filename,
            "OUTPUT_TGZ": output_tgz.path,
        },
    )
    return [DefaultInfo(files = depset(outputs))]

_package = rule(
    implementation = _package_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
        ),
        "generated": attr.label_list(),
        "tars": attr.label_list(),
        "package_dir": attr.string(
            mandatory = True,
        ),
        "chart_name": attr.string(
            mandatory = True,
        ),
        "chart_version": attr.string(
            mandatory = True,
        ),
        "app_version": attr.string(
            mandatory = True,
        ),
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:helm",
            executable = True,
        ),
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/helm:package.sh",
            executable = True,
        ),
    },
)

def package(**kwargs):
    _package(
        package_dir = native.package_name(),
        **kwargs
    )

PackageInfo = provider(
    fields=[
        "chart_name",
        "chart_version",
    ],
)

def _template_impl(ctx):
    output_filename = "{}.yaml".format(ctx.attr.name)
    output_yaml = ctx.actions.declare_file(output_filename)
    outputs = [output_yaml]
    arguments = ctx.actions.args()
    for (key, value) in ctx.attr.set_values.items():
        arguments.add("--set", "{}={}".format(key, value))
    for f in ctx.files.values:
        arguments.add("--values", f.path)
    ctx.actions.run(
        inputs = [ctx.file.chart_package] + ctx.files.values,
        outputs = outputs,
        tools = [ctx.executable._helm],
        progress_message = "Rendering Helm package to {}".format(output_filename),
        executable = ctx.executable._script,
        env = {
            "HELM": ctx.executable._helm.path,
            "INSTALL_NAME": ctx.attr.install_name,
            "NAMESPACE": ctx.attr.namespace,
            "CHART_PACKAGE": ctx.file.chart_package.path,
            "OUTPUT_YAML": output_yaml.path,
        },
        arguments = [arguments],
    )
    return [DefaultInfo(files = depset(outputs))]

template = rule(
    implementation = _template_impl,
    attrs = {
        "set_values": attr.string_dict(
            default = {},
        ),
        "values": attr.label_list(
            default = [],
            allow_files = True,
        ),
        "install_name": attr.string(
            mandatory = True,
        ),
        "namespace": attr.string(
            mandatory = True,
        ),
        "chart_package": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:helm",
            executable = True,
        ),
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/helm:template.sh",
            executable = True,
        ),
    },
)
