# Inspection Helpers

The tools in directory __dev/kube__ help developers inspect kube
clusters and kubecf deployments.

The scripts and their uses are:

  - __klog.sh__:

    Run after kubecf is deployed, this script pulls the kube logs from
    all containers in all kubecf pods, as well as kubecf log files in
    the containers, pod descriptions, events, and resources.

  - __kube-ready-state-check.sh__:

    Run before kubecf is deployed, this script inspects the kube
    cluster for issues known to impede kubecf deployment.

  - __pod-status__:

    Run during or after kubecf is deployed, this script shows a table
    of all pods in the deployment, and their state. Options exists to
    restrict it to a specific namespace, and to watch continously.

