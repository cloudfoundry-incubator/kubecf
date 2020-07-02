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

fly_args=(
    "--target=${target}"
    "set-pipeline"
    "--pipeline=${PIPELINE}"
)

# space-separated paths to template files and directories which contain template files
template_paths="scripts"
templates=$(find ${template_paths} -type f -exec echo "--template="{} \;)

if [[ "$2" =~ "reconciler" ]]; then
    fly "${fly_args[@]}" --config \
        <(gomplate -V --datasource config="$PIPELINE".yaml --file kubecf-pool-reconciler.yaml.gomplate)
else # kubecf pipeline
    fly "${fly_args[@]}" --config \
        <(gomplate -V --datasource config="$PIPELINE".yaml ${templates} --file pipeline.yaml.gomplate)
fi
