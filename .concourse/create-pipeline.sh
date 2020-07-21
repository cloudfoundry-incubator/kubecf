#!/bin/bash

# Usage: ./create_pipeline.sh <concourse-target> <pipeline-name>>
# You can configure all the required values in config yamls: kubecf.yaml, <pipeline-name>.yaml, etc.

set -Eeo pipefail

if ! hash gomplate 2>/dev/null; then
    echo "gomplate missing. Follow the instructions in https://docs.gomplate.ca/installing/ and install it first."
    exit 1
fi

usage() {
    echo "USAGE:"
    echo "$0 <concourse-target> <pipeline-name>"
}

if [[ -z "$1" ]]; then
    echo "Concourse target not provided."
    usage
    exit 1
else
    target=$1
fi

if [[ -z "$2" ]]; then
    echo "Pipeline name not provided."
    usage
    exit 1
else
    if [[ "$2" == "kubecf" || "$2" == "kubecf-pool-reconciler" ]]; then
        printf "This will modify the production pipeline: %s. Are you sure you want to proceed?(yes/no): " "$2"
        read -r ans
        if [[ "$ans" == "y" || "$ans" == "yes" ]]; then
            export PIPELINE=$2
        else
            echo "Operation aborted."
            exit 1
        fi
    else
        if test -f "$2".yaml; then
            export PIPELINE=$2
        else
            echo "$2.yaml doesn't exist."
            usage
            exit 1
        fi
    fi
fi

# Determine if the pipeline being pushed is a new pipeline
existing_pipeline_job_count=$(
  fly --target "${target}" get-pipeline --pipeline "${PIPELINE}" --json | jq '.jobs | length' || true
)
if [[ ${existing_pipeline_job_count} -gt 0 ]]; then
  pipeline_already_existed=true
else
  pipeline_already_existed=false
fi

# Push a new pipeline, or update an existing one
fly_args=(
    "--target=${target}"
    "set-pipeline"
    "--pipeline=${PIPELINE}"
)
if [[ "$2" =~ "reconciler" ]]; then
    fly "${fly_args[@]}" --config \
        <(gomplate -V --datasource config="$PIPELINE".yaml --file kubecf-pool-reconciler.yaml.gomplate)
else # kubecf pipeline
    fly "${fly_args[@]}" --config \
        <(gomplate -V --datasource config="$PIPELINE".yaml --file pipeline.yaml.gomplate)
fi

# If the pipeline being pushed was a *new* pipeline, pause all the 'initial' jobs (jobs without 'passed:' dependencies)
# Important caveat: If a pipeline is updated to add new targets, the new initial jobs will *not* be paused
if ! ${pipeline_already_existed}; then
    jobs_without_dependencies_names=$(
        fly ${target:+"--target=${target}"} get-pipeline --json -p "${PIPELINE}" | jq -r '.jobs - [.jobs[] | select(.plan[] | .passed)] | .[].name'
                                   )
    for job_name in ${jobs_without_dependencies_names}; do
        fly ${target:+"--target=${target}"} pause-job -j "${PIPELINE}/${job_name}"
    done
    fly ${target:+"--target=${target}"} unpause-pipeline --pipeline="${PIPELINE}"
fi
