#!/usr/bin/env bash

scriptname=$(basename "${0}")
minions_value_file="minions-values.yaml"
placement_tags='minions-1'
cp_namespace='kubecf'
#
# Usage statement
# This script generates a helm value file for kubecf worker clusters
# 
usage() {
    echo
    echo "Usage: $scriptname [OPTIONS]"
    echo
    echo "   -o"
    echo "              The output value file name for minions cluster, default is minions-values.yaml"
    echo "   -t"
    echo "              The placement tag for minions cluster, default is minions-1"
    echo "   -n"
    echo "              The namespace of KubeCF control plane, default is kubecf"
    echo
    echo "   -h --help  Output this help."
}

#
# Parameter processing
#
while [[ $# -gt 0 ]]
do
key="$1"
shift
case $key in
    -o)
    minions_value_file=$1
    shift
    ;;
    -t)
    placement_tags=$1
    shift
    ;;
    -n)
    cp_namespace=$1
    shift
    ;;
    -h|--help)
      usage
      exit 0
    ;;
    *)
    echo "@@ERROR: Unrecognised parameter(s): $*"
    usage
    exit 2
    ;;
esac
done

credentials_list=(
credhub_tls.ca
diego_bbs_client.ca
diego_bbs_client.certificate
diego_bbs_client.private_key
diego_instance_identity_ca.ca
diego_instance_identity_ca.certificate
diego_instance_identity_ca.private_key
diego_rep_agent_v2.ca
diego_rep_agent_v2.certificate
diego_rep_agent_v2.private_key
diego_rep_client.ca
diego_rep_client.certificate
diego_rep_client.private_key
forwarder_agent_metrics_tls.ca
forwarder_agent_metrics_tls.certificate
forwarder_agent_metrics_tls.private_key
gorouter_backend_tls.ca
loggr_udp_forwarder_tls.ca
loggr_udp_forwarder_tls.certificate
loggr_udp_forwarder_tls.private_key
loggregator_agent_metrics_tls.ca
loggregator_agent_metrics_tls.certificate
loggregator_agent_metrics_tls.private_key
loggregator_tls_agent.ca
loggregator_tls_agent.certificate
loggregator_tls_agent.private_key
ssh_proxy_backends_tls.ca
uaa_ssl.ca
)

function AddPropertiesFun(){
  cat >>"${minions_value_file}" <<EOF
properties:
  diego-cell:
    rep:
      diego:
        rep:
          placement_tags: ['${placement_tags}']
EOF
}

function AddCredentialsFun(){
  echo "credentials:" >> "${minions_value_file}"
  for (( i = 0 ; i < ${#credentials_list[@]} ; i++ )) do
    credential_type=$(echo "${credentials_list[$i]}" | cut -d "." -f 2)
    credential_name=$(echo "${credentials_list[$i]}" | cut -d "." -f 1 | sed "s/_/-/g" )

    if [ "X${credential_name}" != "X" ] && [ "X${credential_type}" != "X" ]; then
      credential_value=$(kubectl get secret var-"${credential_name}" -n "${cp_namespace}" -o yaml 2> /dev/null | grep "^  ${credential_type}:" | awk '{print $2}' | base64 --decode)
      if [ "X${credential_value}" != "X" ]; then
        echo "  ${credentials_list[$i]}: |" >> "${minions_value_file}"
        for j in ${credential_value}; do
          if [[ "$j" =~ "-----"$ ]] || [ "$j" == "RSA" ] || [ "$j" == "PRIVATE" ]; then
            ${sed_cmd} "$ s/$/ $j/" "${minions_value_file}"
          else
            echo "    $j" >> "${minions_value_file}"
          fi
        done
      else
        echo "Warning: Not find ${credentials_list[$i]}, please manually update it in credentials part in file ${minions_value_file}."
      fi
    fi
  done

  credential_value=$(kubectl get secret var-uaa-clients-tcp-emitter-secret -n "${cp_namespace}" -o yaml 2> /dev/null | grep "^  password:" | awk '{print $2}' | base64 --decode)
  if [ "X${credential_value}" != "X" ]; then
    echo "  uaa_clients_tcp_emitter_secret: ${credential_value}" >> "${minions_value_file}"
  else
    echo "Warning: Not find uaa_clients_tcp_emitter_secret, please manually update it in credentials part in file ${minions_value_file}."
  fi
}

function AddFeaturesFun(){
   cat >>"${minions_value_file}" <<EOF 
features:
  multiple_cluster_mode:
    cell_segment:
      enabled: true
  embedded_database:
    enabled: false
  routing_api:
    enabled: false
  credhub:
    enabled: false
EOF
}

#Check placement tag file
if  [[ -z ${placement_tags} ]]; then
  echo  "Not find placement tag, please provide one with -t option."
  usage
  exit 1
fi

#Check kubectl command
if ! hash kubectl 2>/dev/null; then
  echo "Not find command kubectl, please install it and set it connect to control plane."
  exit 1
fi

#Check if kubectl connected to control plane.
kubectl get pod -n "${cp_namespace}" &> /dev/null
isConnected=$?
if [ "$isConnected" -ne 0 ]; then
  echo "Not find namespace ${cp_namespace}, please set kubectl connect to control plane."
  exit 1
fi

#Check operation system 
os_name=$(uname -a)
if [[ "${os_name}" =~ "Darwin" ]]; then
  sed_cmd="sed -i ''"
else
  sed_cmd="sed -i"
fi

echo "Generating value file for minions cluster ..."
#Add system_domain
system_domain=$(kubectl get secret var-system-domain -n "${cp_namespace}" -o yaml 2> /dev/null | grep "^  value:" | awk '{print $2}' | base64 --decode)
if [ "X$system_domain" == "X" ]; then
  echo "Warning: Not find system domain, please manually update it in file ${minions_value_file}."
else
  echo "add system_domain ..."
  echo "system_domain: $system_domain" >> "${minions_value_file}"
fi

#Add required properties, credentials, inline, features into output value file
echo "add Properties ..."
AddPropertiesFun
echo "add Credentials ..."
AddCredentialsFun
echo "add Features ..."
AddFeaturesFun

echo "Complete. Please check output value file ${minions_value_file}."

