load("//:def.bzl", "project")

def _minikube_start_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export MINIKUBE="{minikube}"
        export K8S_VERSION="${{K8S_VERSION:-{k8s_version}}}"
        export VM_CPUS="${{VM_CPUS:-{vm_cpus}}}"
        export VM_MEMORY="${{VM_MEMORY:-{vm_memory}}}"
        export VM_DISK_SIZE="${{VM_DISK_SIZE:-{vm_disk_size}}}"
        export ISO_URL="${{ISO_URL:-{iso_url}}}"
        export HELM_INIT="{helm_init}"
        "{script}"
    """.format(
        minikube = ctx.executable._minikube.path,
        k8s_version = ctx.attr.k8s_version,
        vm_cpus = ctx.attr.vm_cpus,
        vm_memory = ctx.attr.vm_memory,
        vm_disk_size = ctx.attr.vm_disk_size,
        iso_url = ctx.attr.iso_url,
        helm_init = ctx.executable._helm_init.short_path,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._minikube,
        ctx.executable._helm_init,
        ctx.executable._script,
    ]
    helm_init_runfiles = ctx.attr._helm_init[DefaultInfo].data_runfiles
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles).merge(helm_init_runfiles),
    )]

attrs = {
    "k8s_version": attr.string(
        default = "v{}".format(project.kubernetes.version),
    ),
    "vm_cpus": attr.string(
        default = "4",
    ),
    "vm_memory": attr.string(
        default = "{}".format(1024 * 12),
    ),
    "vm_disk_size": attr.string(
        default = "120g",
    ),
    "iso_url": attr.string(
        default = "https://github.com/f0rmiga/opensuse-minikube-image/releases/download/v0.1.0/minikube-openSUSE.x86_64-1.0.0.iso",
    ),
    "_minikube": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "@minikube//:minikube",
        executable = True,
    ),
    "_helm_init": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "//rules/helm:init",
        executable = True,
    ),
}

minikube_start_binary = rule(
    implementation = _minikube_start_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//dev/minikube:start.sh",
            executable = True,
        ),
    }, **attrs),
    executable = True,
)

minikube_delete_binary = rule(
    implementation = _minikube_start_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//dev/minikube:delete.sh",
            executable = True,
        ),
    }, **attrs),
    executable = True,
)
