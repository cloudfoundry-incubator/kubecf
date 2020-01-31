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
        "{script}"
    """.format(
        minikube = ctx.executable._minikube.short_path,
        k8s_version = ctx.attr.k8s_version,
        vm_cpus = ctx.attr.vm_cpus,
        vm_memory = ctx.attr.vm_memory,
        vm_disk_size = ctx.attr.vm_disk_size,
        iso_url = ctx.attr.iso_url,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._minikube,
        ctx.executable._script,
    ]
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles),
    )]

attrs = {
    "k8s_version": attr.string(
        default = "v{}".format(project.kubernetes.version),
    ),
    "vm_cpus": attr.string(
        default = "4",
    ),
    "vm_memory": attr.string(
        default = "{}".format(1024 * 16),
    ),
    "vm_disk_size": attr.string(
        default = "120g",
    ),
    "iso_url": attr.string(
        default = "https://github.com/f0rmiga/opensuse-minikube-image/releases/download/v0.1.6/minikube-openSUSE.x86_64-0.1.6.iso",
    ),
    "_minikube": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "@minikube//:minikube",
        executable = True,
    ),
}

start_binary = rule(
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

delete_binary = rule(
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

def _minikube_load_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export MINIKUBE="{minikube}"
        DOCKER_IMAGES=()
    """.format(minikube = ctx.executable._minikube.short_path)

    # Add the docker saved tarballs to load
    for image in ctx.attr.images:
        for file in image.files.to_list():
            contents += """
                DOCKER_IMAGES+=('{path}')
            """.format(path = file.short_path)

    contents += """
        source "{script}"
    """.format(script = ctx.executable._script.path)
    ctx.actions.write(executable, contents, is_executable = True)

    runfiles = [
        ctx.executable._minikube,
        ctx.executable._script,
    ] + ctx.files.images

    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles),
    )]

load_binary = rule(
    implementation = _minikube_load_impl,
    attrs = {
        "images": attr.label_list(
            allow_empty = False,
            doc = "Docker images to pre-load into the cluster",
            allow_files = [".tar"],
        ),
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//dev/minikube:load.sh",
            executable = True,
        ),
        "_minikube": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@minikube//:minikube",
            executable = True,
        ),
    },
    executable = True,
)
