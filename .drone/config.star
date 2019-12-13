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

    steps.append(step(
        name = "external-binaries",
        commands = ["bash {}/runtime/binaries.sh".format(DRONE_BASE_PATH)],
    ))

    for linter in ["shellcheck", "yamllint", "helmlint"]:
        steps.append(step(
            name = "lint:{}".format(linter),
            commands = ["./dev/linters/{}.sh".format(linter)],
        ))

    steps.append(step(
        name = "build",
        commands = ["{}/steps/build/build.sh".format(DRONE_BASE_PATH)],
    ))

    steps.append(step(
        name = "deploy:kind",
        commands = [
            "{}/steps/deploy/cleanup.sh".format(DRONE_BASE_PATH),
            "{}/steps/deploy/kind.sh".format(DRONE_BASE_PATH),
        ],
        extra_volumes = [
            docker_sock_volume(),
            kube_volume(),
        ],
        network_mode = "host",
    ))

    for component in ["cf_operator", "kubecf"]:
        steps.append(step(
            name = "deploy:{}".format(component),
            commands = [
                "{}/steps/deploy/{}.sh".format(DRONE_BASE_PATH, component),
                "{}/steps/deploy/wait_{}.sh".format(DRONE_BASE_PATH, component),
            ],
            extra_volumes = [
                kube_volume(),
            ],
            network_mode = "host",
        ))

    steps.append(test_step("smoke_tests"))
    steps.append(test_step("cf_acceptance_tests"))

    steps.append(step(
        name = "cleanup:kind",
        commands = [
            "{}/steps/deploy/cleanup.sh".format(DRONE_BASE_PATH),
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
KUBE_VOLUME_NAME = "kube"
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
        "name": name,
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
        name = "test:{}".format(name),
        commands = [
            "{}/steps/test/{}.sh".format(DRONE_BASE_PATH, name),
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
        "name": KUBE_VOLUME_NAME,
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
            "name": KUBE_VOLUME_NAME,
            "temp": {},
        },
        {
            "name": TMP_VOLUME_NAME,
            "temp": {},
        },
    ]
