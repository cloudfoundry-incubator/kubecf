#!/usr/bin/env bash
# Helper functions for the cf-acceptance-tests step scripts.
# I.e determine pod names, existence, state, termination
# Ditto for associated jobs. And other miscellanea.

ig_job_name() {
    kubectl get jobs \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --output name \
	    2> /dev/null \
	| grep "ig-"
}

ig_job_exists() {
    kubectl get jobs \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --output name \
	    2> /dev/null \
	| grep --quiet "ig-"
}

wait_for_ig_job() {
    # Waiting twice. For the job to be created/appear, and for it to
    # complete/disappear again. After that we assume that the BDPL
    # has settled and reconfigured to contain our changes.

    # FUTURE: See if there is a more direct way of determining this,
    # like a deployment state ?!
    # Complaint wrong. The echo generates a traling newline the `blue` doesn't.
    # shellcheck disable=SC2005
    echo "$(blue "Waiting for the ig job to start...")"

    local timeout="360"
    until ig_job_exists || [[ "$timeout" == "0" ]]
    do sleep 1; timeout=$((timeout - 1))
    done
    if [[ "${timeout}" == 0 ]]; then
	# shellcheck disable=SC2005
	>&2 echo "$(red "Timed out waiting for the ig job to be created")"
	return 1
    fi

    job_name="$(ig_job_name)"
    echo "$(green "Job exists"):  $(blue "${job_name}")"

    # shellcheck disable=SC2005
    echo "$(blue "Waiting for the ig job to complete...")"

    local timeout="360"
    while ig_job_exists && [[ "$timeout" -gt 0 ]]
    do sleep 1; timeout=$((timeout - 1))
    done
    if [[ "${timeout}" == 0 ]]; then
	# shellcheck disable=SC2005
	>&2 red "Timed out waiting for the ig job to complete"
	return 1
    fi

    # shellcheck disable=SC2005
    blue "Completed ig job, continue..."
    return 0
}

cf_acceptance_tests_job_name() {
    kubectl get jobs \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --output name \
	    2> /dev/null \
	| grep "acceptance-tests"
}

cf_acceptance_tests_pod_name() {
    kubectl get pods \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --output name \
	    2> /dev/null \
	| grep "acceptance-tests"
}

cf_acceptance_tests_pod_exists() {
    kubectl get pods \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --output name \
	    2> /dev/null \
	| grep --quiet "acceptance-tests"
}

cf_acceptance_tests_pod_running() {
    pod_name="${1}"
    kubectl get "${pod_name}" \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --output jsonpath='{.status.containerStatuses[?(@.name == "acceptance-tests-acceptance-tests")].state.running}' \
	    2> /dev/null
}

# Wait for cf-acceptance-tests to start.
wait_for_cf_acceptance_tests_pod() {
    # shellcheck disable=SC2005
    echo "$(blue "Waiting for the cf-acceptance-tests pod to start...")"
    local timeout="300"
    until cf_acceptance_tests_pod_exists || [[ "$timeout" == "0" ]]
    do
	sleep 1; timeout=$((timeout - 1))
    done
    if [[ "${timeout}" == 0 ]]; then
	# shellcheck disable=SC2005
	>&2 echo "$(red "Timed out waiting for the cf-acceptance-tests pod to be created")"
	return 1
    fi
    pod_name="$(cf_acceptance_tests_pod_name)"
    echo "$(green "Pod exists"):  $(blue "${pod_name}")"

    until [[ "$(cf_acceptance_tests_pod_running "${pod_name}")" != "" ]] || [[ "$timeout" == "0" ]]
    do
	sleep 1; timeout=$((timeout - 1))
    done
    if [[ "${timeout}" == 0 ]]; then
	# shellcheck disable=SC2005
	>&2 echo "$(red "Timed out waiting for the cf-acceptance-tests pod to come online")"
	return 1
    fi
    echo "$(green "Pod running"): $(blue "${pod_name}")"
    return 0
}

# Follow the logs. If the tests fail, the logs command will also fail.
cf_acceptance_tests_pod_follow_log() {
    pod_name="${1}"
    kubectl logs \
	    --follow "${pod_name}" \
	    --namespace "${KUBECF_NAMESPACE}" \
	    --container acceptance-tests-acceptance-tests
}

# Wait for the container to terminate and provide the container's exit
# code to the caller
wait_for_cf_acceptance_tests_termination() {
    pod_name="${1}"
    jsonpath='{.status.containerStatuses[?(@.name == "acceptance-tests-acceptance-tests")].state.terminated.exitCode}'
    while true; do
	exit_code="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}")"
	if [[ -n "${exit_code}" ]]; then
	    break
	fi
	sleep 1
    done
    echo "${exit_code}"
}

# Core of CAT execution
run_cf_acceptance_tests() {
    # Trigger cf-acceptance-tests.
    bazel run //testing/acceptance_tests

    wait_for_cf_acceptance_tests_pod || exit 1

    pod_name="$(cf_acceptance_tests_pod_name)"

    # Follow the logs. If the tests fail, the logs command will also
    # fail.
    cf_acceptance_tests_pod_follow_log "${pod_name}"

    # Wait for the container to terminate, ...
    exit_code="$(wait_for_cf_acceptance_tests_termination "${pod_name}")"

    job_name="$(cf_acceptance_tests_job_name)"

    if [[ "$exit_code" == "0" ]]; then
	echo "$(green "Container completed")", cleaning up "$(blue "${job_name}")"
    else
	echo "$(red "Container completed")", cleaning up "$(blue "${job_name}")"
    fi

    # ... then drop the job (**). This prevents any restart and
    # removes the pod as well (this we do not wait for (yet)), ...
    # (**) Hacks around https://github.com/SUSE/kubecf/issues/324

    kubectl delete --namespace "${KUBECF_NAMESPACE}" "${job_name}"

    # Route/return the exit code through a file, we need stdout for
    # the display of the test log itself.
    > EXIT echo "${exit_code}"
}

# color codes
# - 30 black - 31 red - 32 green - 33 yellow - 34 blue - 35 magenta - 36 cyan - 37 white

function red()   { printf '\e[31m%b\e[0m' "$1" ; }
function green() { printf '\e[32m%b\e[0m' "$1" ; }
function blue()  { printf '\e[34m%b\e[0m' "$1" ; }
function cyan()  { printf '\e[36m%b\e[0m' "$1" ; }
