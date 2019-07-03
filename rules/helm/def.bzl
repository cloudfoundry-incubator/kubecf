def _package_impl(ctx):
    output_filename = "{}-{}.tgz".format(ctx.attr.chart_name, ctx.attr.chart_version)
    output_tgz = ctx.actions.declare_file(output_filename)
    outputs = [output_tgz]
    ctx.actions.run_shell(
        inputs = [] + ctx.files.srcs + ctx.files.tars,
        outputs = outputs,
        tools = [ctx.executable._helm],
        progress_message = "Generating Helm package archive {}".format(output_filename),
        command = """
            build_dir="tmp/build/{package_dir}"
            mkdir -p "${{build_dir}}"
            cp --dereference --recursive "{package_dir}"/* "${{build_dir}}"

            for t in {tars}; do
                tar xf "${{t}}" -C "${{build_dir}}"
            done

            {helm} init --client-only > /dev/null
            {helm} package "${{build_dir}}" \
                --version="{chart_version}" \
                --app-version="{app_version}" > /dev/null
            mv "{output_filename}" "{output_tgz}"

            echo "Files added to Helm package archive:\n"
            tar tf "{output_tgz}"
            echo ""
        """.format(
            tars = " ".join([f.path for f in ctx.files.tars]),
            helm = ctx.executable._helm.path,
            package_dir = ctx.attr.package_dir,
            chart_version = ctx.attr.chart_version,
            app_version = ctx.attr.app_version,
            output_filename = output_filename,
            output_tgz = output_tgz.path,
        ),
    )
    return [DefaultInfo(files = depset(outputs))]

_package = rule(
    implementation = _package_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
        ),
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
    },
)

def package(**kwargs):
    _package(
        package_dir = native.package_name(),
        **kwargs
    )
