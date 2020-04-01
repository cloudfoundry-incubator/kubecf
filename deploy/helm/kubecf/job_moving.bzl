"""
An extension for extracting jobs from existing instance groups and creating new ones based on these
job definitions.
"""

load("//rules/yaml_extractor:defs.bzl", "yaml_extractor")

# The default list of jobs related to log-cache.
LOG_CACHE_JOBS = [
    "log-cache",
    "log-cache-gateway",
    "log-cache-nozzle",
    "log-cache-cf-auth-proxy",
    "route_registrar",
]

def extract_log_cache(instance_group, log_cache_jobs):
    """A macro to extract the log-cache jobs.

    Args:
        instance_group: the instance group where the log-cache jobs live.
        log_cache_jobs: the list of jobs to extract from the instance_group.

    Returns:
        The list of target names created by this macro.
    """
    targets = []
    for job in log_cache_jobs:
        name = "log_cache_{}_job".format(job).replace("-", "_")
        targets.append(":{}".format(name))
        yaml_extractor(
            name = name,
            src = "@cf_deployment//:cf-deployment.yml",
            filter = """.instance_groups[] | select(.name == "{instance_group}") | .jobs[] | select(.name == "{job}")""".format(
                instance_group = instance_group,
                job = job,
            ),
        )
    return targets
