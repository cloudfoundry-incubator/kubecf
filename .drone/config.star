DRONE_BASE_PATH = ".drone/pipelines/default"

def main(ctx):
    pipeline = {
        "kind": "pipeline",
        "type": "docker",
        "name": "default",
    }

    pipeline["trigger"] = {
        "ref": [
            "refs/heads/test/**",
            "refs/heads/master",
        ],
    }

    steps = []

    # Execute the binaries.sh script first to build the external binaries cache.
    steps.append(step(
        name = "external-binaries",
        commands = ["{base_path}/runtime/binaries.sh".format(base_path = DRONE_BASE_PATH)],
    ))

    for linter in ["shellcheck", "yamllint", "helmlint"]:
        steps.append(step(
            name = "lint:{linter}".format(linter = linter),
            commands = ["dev/linters/{linter}.sh".format(linter = linter)],
        ))

    steps.append(step(
        name = "build",
        commands = ["{base_path}/steps/build/build.sh".format(base_path = DRONE_BASE_PATH)],
    ))

    steps.append(step(
        name = "deploy:kind",
        commands = [
            "{base_path}/steps/deploy/cleanup.sh".format(base_path = DRONE_BASE_PATH),
            "{base_path}/steps/deploy/kind.sh".format(base_path = DRONE_BASE_PATH),
        ],
        extra_volumes = [
            docker_sock_volume(),
            kube_volume(),
        ],
        network_mode = "host",
    ))

    for component in ["cf_operator", "kubecf"]:
        steps.append(step(
            name = "deploy:{component}".format(component = component),
            commands = [
                "{base_path}/steps/deploy/{component}.sh".format(
                    base_path = DRONE_BASE_PATH,
                    component = component,
                ),
                "{base_path}/steps/deploy/wait_{component}.sh".format(
                    base_path = DRONE_BASE_PATH,
                    component = component,
                ),
            ],
            extra_volumes = [
                kube_volume(),
            ],
            network_mode = "host",
        ))

    steps.append(test_step("smoke_tests"))
    steps.append(test_step("cf_acceptance_tests"))
    steps.append(test_step("kubecf_redeploy_cats_internetless"))
    steps.append(test_step("cf_acceptance_tests"))

    steps.append(step(
        name = "cleanup:kind",
        commands = [
            "{base_path}/steps/deploy/cleanup.sh".format(base_path = DRONE_BASE_PATH),
        ],
        extra_volumes = [
            docker_sock_volume(),
        ],
        when = {
            "status": [
                "success",
                "failure",
            ],
        }
    ))

    pipeline["steps"] = steps

    pipeline["volumes"] = volumes()

    return pipeline


BAZEL_CACHE_VOLUME_NAME = "bazel-cache"
DOCKER_SOCK_VOLUME_NAME = "docker-sock"
DOCKER_SOCK_PATH = "/var/run/docker.sock"
KUBE_CONFIG_VOLUME_NAME = "kube"
TMP_VOLUME_NAME = "tmp"

def step(
    name,
    commands,
    extra_volumes = [],
    image = "thulioassis/bazel-docker-image:1.2.1",
    network_mode = None,
    when = None,
):
    step = {
        "name": name.replace("_", "-"),
        "commands": commands,
        "image": image,
        "volumes": extra_volumes + [
            {
                "name": BAZEL_CACHE_VOLUME_NAME,
                "path": "/root/.cache/bazel",
            },
            {
                "name": TMP_VOLUME_NAME,
                "path": "/tmp",
            },
        ],
    }

    if network_mode:
        step["network_mode"] = network_mode

    if when:
        step["when"] = when

    return step

def test_step(name):
    return step(
        name = "test:{name}".format(name = name),
        commands = [
            "{base_path}/steps/test/{name}.sh".format(
                base_path = DRONE_BASE_PATH,
                name = name,
            ),
        ],
        extra_volumes = [
            kube_volume(),
        ],
        network_mode = "host",
    )

def docker_sock_volume():
    return {
        "name": DOCKER_SOCK_VOLUME_NAME,
        "path": DOCKER_SOCK_PATH,
    }

def kube_volume():
    return {
        "name": KUBE_CONFIG_VOLUME_NAME,
        "path": "/root/.kube",
    }

def volumes():
    return [
        {
            "name": BAZEL_CACHE_VOLUME_NAME,
            "host": {
                "path": "/tmp/drone/bazel_cache",
            },
        },
        {
            "name": DOCKER_SOCK_VOLUME_NAME,
            "host": {
                "path": DOCKER_SOCK_PATH,
            },
        },
        {
            "name": KUBE_CONFIG_VOLUME_NAME,
            "temp": {},
        },
        {
            "name": TMP_VOLUME_NAME,
            "temp": {},
        },
    ]
