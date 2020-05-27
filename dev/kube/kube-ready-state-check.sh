#!/bin/bash

function usage() {
    cat <<EOF
Usage: $(basename "${0}") [options] [category]

  -h: Displays this help message

  Supported categories: all, api, kube, node
  Defaults to: all
EOF
}

while getopts "h" opt; do
    case $opt in
	h)
	    usage
	    exit
	    ;;
	*)  usage
	    exit
	    ;;
    esac
done

shift $((OPTIND-1))

category="${1:-all}"
case ${category} in
    all|api|kube|node)
	: # ok, nothing to do
	;;
    *) usage
	exit 1
	;;
esac

#Script to determine is the K8s host is "ready" for cf deployment
FAILED=0

function has_command() {
    type "${1}" &> /dev/null ;
}

function green() {
    printf '\e[32m%b\e[0m' "$1"
}

function red() {
    printf '\e[31m%b\e[0m' "$1"
}

function verified() {
    printf 'Verified: %s\n' "$(green "${1}")"
}

function trouble() {
    printf 'Configuration problem detected: %s\n' "$(red "${1}")"
}

function status() {
    # While the indirect check is not nice to shellcheck, at the
    # higher-level our use of `... check command ; status label ; ...`
    # is much more readable. It also avoids the creation of a lot of
    # helper functions otherwise needed to group the more complex
    # checking commands into something which can be run by `if cmd`.
    # --> Overriding shellcheck here.
    #
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
	verified "$1"
    else
	trouble "$1"
	FAILED=1
    fi
}

function having_category() {
    # `all` matches always
    set -- all "$@"
    case "$@" in
	*${category}*)
	    return 0
	    ;;
    esac
    return 1
}

echo "Testing $(green "${category}")"

# kernel version should be >= 3.19
if having_category node; then
    desired_kernel_version=3.19
    version=$(uname -r | cut -c1-4)
    if (( $(awk 'BEGIN {print ("'"$version"'" >= "'$desired_kernel_version'")}') )); then
        status "kernel version must be equal to or greater than 3.19"
    else
        trouble "kernel version should not be lower than 3.19"
    fi
fi

# max_user_namespaces must be >= 10000, see https://github.com/cloudfoundry-incubator/kubecf/issues/484
if having_category node ; then
    ns=$(cat /proc/sys/user/max_user_namespaces)
    if [ $((ns)) -ge 10000 ] ; then
        status "user_max_namespaces set to greater than 10000"
    else 
        trouble "user_max_namespaces should be set to more than 10000"
    fi
fi

# swap should be accounted
if having_category node ; then
    # https://www.kernel.org/doc/Documentation/cgroup-v1/memory.txt - section 2.4.
    dir="/sys/fs/cgroup/memory"
    test -e "${dir}/memory.memsw.usage_in_bytes" && test -e "${dir}/memory.memsw.limit_in_bytes"
    status "swap should be accounted"
fi

# docker info should not show aufs
if having_category node ; then
    docker info 2> /dev/null | grep -vwq "Storage Driver: aufs"
    status "docker info should not show aufs"
fi

# kube auth
if having_category kube ; then
    kubectl auth can-i get pods --namespace=kube-system &> /dev/null
    status "authenticate with kubernetes cluster"
fi

# kube-dns shows all pods ready
# This check should handle core-dns pods as well, see https://github.com/coredns/deployment/issues/116
if having_category kube ; then
    kubectl get pods --namespace=kube-system --selector k8s-app=kube-dns 2> /dev/null | grep -Eq '([0-9])/\1 *Running'
    status "all kube-dns pods should be running (show N/N ready)"
fi

# ntp or systemd-timesyncd is installed and running
if having_category api node ; then
    pgrep -x ntpd >& /dev/null || pgrep -x chronyd >& /dev/null || systemctl is-active systemd-timesyncd >& /dev/null
    status "An ntp daemon or systemd-timesyncd must be installed and active"
fi

# At least one storage class exists in K8s
if having_category kube ; then
    test ! "$(kubectl get storageclasses 2>&1 | grep -e "No resources found." -e "Unable to connect to the server")"
    status "A storage class should exist in K8s"
fi

# privileged pods are enabled in K8s
if having_category api ; then	
    pgrep -ax 'hyperkube|(kube-)?apiserver' | grep apiserver | grep --silent -- --allow-privileged	
    status "Privileged must be enabled in 'kube-apiserver'"	
fi

# override tasks infinity in systemd configuration
if having_category node ; then
    if has_command systemctl ; then
        if systemctl cat --quiet containerd.service >/dev/null 2>/dev/null ; then
            test "$(systemctl show containerd | awk -F= '/TasksMax/ { print substr($2,0,10) }') -gt $((1024 * 1024))"
            status "TasksMax must be set to infinity"
        else
            trouble "containerd.service not available"
        fi
    else
        test "$(awk '/processes/ {print $3}' /proc/"$(pgrep -x containerd)"/limits)" -gt 4096
        status "Max processes should be unlimited, or as high as possible for the system"
    fi
fi

exit $FAILED
