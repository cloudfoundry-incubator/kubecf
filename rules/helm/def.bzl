def _package_impl(ctx):
    output_filename = "{}.tgz".format(ctx.attr.name)
    output_tgz = ctx.actions.declare_file(output_filename)
    outputs = [output_tgz]
    package_script = ctx.actions.declare_file("package.rb")
    multipath_sep = "||"
    ctx.actions.expand_template(
        output = package_script,
        substitutions = {
            "[[package_dir]]": ctx.attr.package_dir,
            "[[multipath_sep]]": multipath_sep,
            "[[tars]]": multipath_sep.join([f.path for f in ctx.files.tars]),
            "[[generated]]": multipath_sep.join([f.path for f in ctx.files.generated]),
            "[[helm]]": ctx.executable._helm.path,
            "[[output_tgz]]": output_tgz.path,
        },
        template = ctx.file._script_tmpl,
    )
    ctx.actions.run_shell(
        command = "ruby {}".format(package_script.path),
        inputs = [package_script] + ctx.files.srcs + ctx.files.tars + ctx.files.generated,
        outputs = outputs,
        tools = [ctx.executable._helm],
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
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:binary",
            executable = True,
        ),
        "_script_tmpl": attr.label(
            allow_single_file = True,
            default = "//rules/helm:package_tmpl_rb",
        ),
    },
)

def package(**kwargs):
    _package(
        package_dir = native.package_name(),
        **kwargs
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
            default = "@helm//:binary",
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

def _version_impl(ctx):
    script = ctx.actions.declare_file("{}.rb".format(ctx.attr.name))
    output = ctx.actions.declare_file("version.txt")
    outputs = [output]
    contents = """
        open('{output}', 'w') do |f|
          f << `{helm} inspect chart {chart}`[/version: (.*)/, 1]
          exit 1 if not $?.success?
        end
    """.format(
        output = output.path,
        helm = ctx.executable._helm.path,
        chart = ctx.file.chart.path,
    )
    ctx.actions.write(script, contents)
    ctx.actions.run_shell(
        command = "ruby {}".format(script.path),
        inputs = [
            script,
            ctx.file.chart,
        ],
        outputs = outputs,
        tools = [ctx.executable._helm],
    )
    return [DefaultInfo(files = depset(outputs))]

version = rule(
    implementation = _version_impl,
    attrs = {
        "chart": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:binary",
            executable = True,
        ),
    },
)
