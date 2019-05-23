#!/bin/bash

set -e

KLOG=${HOME}/klog

if [ "$1" == "-h" ]; then
  cat <<EOF
usage: $0 [-f] [-v] [INSTANCE_ID]

  -f  forces fetching of all logs even if a cache already exists

  INSTANCE_ID defaults to "scf"
EOF
  exit
fi

FORCE=0
if [ "$1" == "-f" ]; then
  shift
  FORCE=1
fi

NS=${1-scf}
DONE="${KLOG}/${NS}/done"

# Prevent bail out.
if [ "${FORCE}" == "1" ] ; then
  rm -f "${DONE}" 2> /dev/null
fi

# Bail out early when already done.
if [ -f "${DONE}" ]; then
    printf "Already done\n"
    exit
fi

function get_pod_phase() {
  kubectl get pod "${POD}" --namespace "${NS}" --output=jsonpath='{.status.phase}'
}

function check_for_log_dir() {
  kubectl exec "${POD}" --namespace "${NS}" --container "${CONTAINER}" \
    -- bash -c "[ -d /var/vcap/sys/log ]" \
    2> /dev/null
}

function get_all_the_pods() {
  kubectl get pods --namespace "${NS}" --output=jsonpath='{.items[*].metadata.name}'
}

function get_containers_of_pod() {
  kubectl get pods "${POD}" --namespace "${NS}" --output=jsonpath='{.spec.containers[*].name}'
}

# Get the CF logs inside the pod.
function retrieve_container_cf_logs() {
  printf " CF"
  kubectl cp --namespace "${NS}" --container "${CONTAINER}" \
    "${POD}":/var/vcap/sys/log/ \
    "${CONTAINER_DIR}/" \
    2> /dev/null > /dev/null
}

# Get the pod logs - Note that previous may not be there if it was
# successful on the first run. Unfortunately we can't get anything
# past the previous one.
function retrieve_container_kube_logs() {
  printf " Kube"
  kubectl logs "${POD}" --namespace "${NS}" --container "${CONTAINER}"            > "${CONTAINER_DIR}/kube.log"
  kubectl logs "${POD}" --namespace "${NS}" --container "${CONTAINER}" --previous > "${CONTAINER_DIR}/kube-previous.log"
}

function get_pod_description() {
  printf "  Descriptions ...\n"
  kubectl describe pods "${POD}" --namespace "${NS}" > "${POD_DIR}/describe-pod.txt"
}

function get_all_resources() {
  printf "Resources ...\n"
  kubectl get all --export=true --namespace "${NS}" --output=yaml > "${KLOG}/${NS}/resources.yaml"
}

function get_all_events() {
  printf "Events ...\n"
  kubectl get events --export=true --namespace "${NS}" --output=yaml > "${KLOG}/${NS}/events.yaml"
}

rm -rf "${KLOG:?}/${NS:?}"
NAMESPACE_DIR="${KLOG}/${NS}"

# Iterate over pods and their containers.
PODS=($(get_all_the_pods))

for POD in "${PODS[@]}"; do
  POD_DIR="${NAMESPACE_DIR}/${POD}"
  PHASE="$(get_pod_phase)"

  printf "Pod \e[0;32m$POD\e[0m = $PHASE\n"

  # Iterate over containers and dump logs.
  CONTAINERS=($(get_containers_of_pod))
  for CONTAINER in "${CONTAINERS[@]}"; do
    printf "  - \e[0;32m${CONTAINER}\e[0m logs:"

    CONTAINER_DIR="${POD_DIR}/${CONTAINER}"
    mkdir -p ${CONTAINER_DIR}

    # Get the CF logs only if there are any.
    if [ "${PHASE}" != 'Succeeded' ] && check_for_log_dir; then
      retrieve_container_cf_logs
    fi

    retrieve_container_kube_logs 2> /dev/null || true
    printf "\n"
  done

  get_pod_description
done

get_all_resources
get_all_events

printf "Packaging it all up ...\n"

tar -zcf klog.tar.gz "${KLOG}"

printf "\e[0;32mDone\e[0m\n"
touch "${DONE}"
exit
