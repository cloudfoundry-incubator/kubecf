def _kubectl_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export KUBECTL="{kubectl}"
        export RESOURCE="{resource}"
        export NAMESPACE="{namespace}"
        "{script}"
    """.format(
        kubectl = ctx.executable._kubectl.path,
        resource = ctx.file.resource.short_path,
        namespace = ctx.attr.namespace,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._kubectl,
        ctx.executable._script,
        ctx.file.resource,
    ]
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles),
    )]

_kubectl_attr = {
    "_kubectl": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "@kubectl//:kubectl",
        executable = True,
    ),
}

_attrs = dict({
    "namespace": attr.string(
        mandatory = True,
    ),
    "resource": attr.label(
        mandatory = True,
        allow_single_file = True,
    ),
}, **_kubectl_attr)

apply = rule(
    implementation = _kubectl_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/kubectl:apply.sh",
            executable = True,
        ),
    }, **_attrs),
    executable = True,
)

delete = rule(
    implementation = _kubectl_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/kubectl:delete.sh",
            executable = True,
        ),
    }, **_attrs),
    executable = True,
)

def _kubectl_patch_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export KUBECTL="{kubectl}"
        export NAMESPACE="{namespace}"
        export RESOURCE_TYPE="{resource_type}"
        export RESOURCE_NAME="{resource_name}"
        export PATCH_TYPE="{patch_type}"
        export PATCH_FILE="{patch_file}"
        "{script}"
    """.format(
        kubectl = ctx.executable._kubectl.path,
        namespace = ctx.attr.namespace,
        resource_type = ctx.attr.resource_type,
        resource_name = ctx.attr.resource_name,
        patch_type = ctx.attr.patch_type,
        patch_file = ctx.file.patch_file.short_path,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._kubectl,
        ctx.executable._script,
        ctx.file.patch_file,
    ]
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles),
    )]

patch = rule(
    implementation = _kubectl_patch_impl,
    attrs = dict({
        "namespace": attr.string(
            mandatory = True,
        ),
        "resource_type": attr.string(
            mandatory = True,
        ),
        "resource_name": attr.string(
            mandatory = True,
        ),
        "patch_type": attr.string(
            mandatory = True,
        ),
        "patch_file": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/kubectl:patch.sh",
            executable = True,
        ),
    }, **_kubectl_attr),
    executable = True,
)
