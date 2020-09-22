#!/usr/bin/env bash

scriptname=$(basename "${0}")
minions_value_file="minions-values.yaml"
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
cf_app_sd_client_tls.ca
cf_app_sd_client_tls.certificate
cf_app_sd_client_tls.private_key
nats_client_cert.ca
nats_client_cert.certificate
nats_client_cert.private_key
network_policy_client.ca
network_policy_client.certificate
network_policy_client.private_key
silk_daemon.ca
silk_daemon.certificate
silk_daemon.private_key
)


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
  embedded_database:
    enabled: false
  routing_api:
    enabled: false
  credhub:
    enabled: false
  multiple_cluster_mode:
    control_plane:
      enabled: false
    cell_segment:
      enabled: true
    control_plane_workers:
      uaa:
        name: uaa
        addresses:
EOF
    #temp_log="temp_log"
    kubectl get pods -n kubecf -o wide | grep uaa |awk '{print$6}' > temp_log
    # uaa
    while read -r ip
    do
     echo "        - ip: $ip" >> "${minions_value_file}"
    done < temp_log
    
    # diego-api
    kubectl get pods -n kubecf -o wide | grep diego-api |awk '{print$6}' > temp_log
    cat >>"${minions_value_file}" << EOF
      diego_api:
        name: diego-api
        addresses:
EOF
    while read -r ip 
    do
      echo "        - ip: $ip" >> diego_api.yaml
    done < temp_log
    cat diego_api.yaml >> "${minions_value_file}"

    # api
    kubectl get pods -n kubecf -o wide | grep api |grep -v diego-api|grep -v log-api|awk '{print$6}' > temp_log
    cat >>"${minions_value_file}" << EOF
      api:
        name: api
        addresses:
EOF
    while read -r ip 
    do
     echo "        - ip: $ip" >> api_vms.yaml
    done < temp_log
    cat api_vms.yaml >> "${minions_value_file}"
    
    # singleton_blobstore
    kubectl get pods -n kubecf -o wide | grep singleton-blobstore|awk '{print$6}' > temp_log
    cat >>"${minions_value_file}" << EOF
      singleton_blobstore:
        name: singleton_blobstore
        addresses:
EOF
    while read -r ip 
    do
      echo "        - ip: $ip" >> "${minions_value_file}"
    done < temp_log
  
  nats_password=$(kubectl get secret var-nats-password -n kubecf -o yaml 2> /dev/null | grep "^  password:" | awk '{print $2}' | base64 --decode)
  
  #nats
  kubectl get pods -n kubecf -o wide | grep nats|awk '{print$6}' > temp_log
  while read -r ip 
  do
     echo "        - ip: $ip" >> nats_vms.yaml
  done < temp_log
  { cat  <<EOF
    provider_link_service:
      nats:
        secret_name: minion-link-nats
        service_name: minion-service-nats
        addresses:
EOF
  cat nats_vms.yaml
  cat << EOF
        link:  |
          ---
          nats.user: "nats"
          nats.password: "${nats_password}"
          nats.hostname: "nats.service.cf.internal"
          nats.port: 4222
      nats_tls:
        secret_name: minion-link-nats-tls
        service_name: minion-service-nats-tls
        addresses:
EOF
  cat nats_vms.yaml
  cat << EOF
        link:  |
          ---
          nats.user: "nats"
          nats.password: "${nats_password}"
          nats.hostname: "nats.service.cf.internal"
          nats.port: 4224
          nats.cluster_port: 4225
EOF
} >> "${minions_value_file}"
  nats_ca=$(kubectl get secret var-nats-ca -n kubecf -o yaml 2> /dev/null | grep "^  certificate:" | awk '{print $2}' | base64 --decode) 
  if [ "X${nats_ca}" != "X" ]; then   
      echo "          nats.external.tls.ca: |" >> "${minions_value_file}"
      for j in ${nats_ca}; do
        if [[ "$j" =~ "-----"$ ]] || [ "$j" == "RSA" ] || [ "$j" == "PRIVATE" ]; then
          ${sed_cmd} "$ s/$/ $j/" "${minions_value_file}"
        else
          echo "            $j" >> "${minions_value_file}"
        fi
      done
  else
      echo "Warning: Not find , please manually update it in credentials part in file ${minions_value_file}."
  fi

  cat >>"${minions_value_file}" << EOF
      doppler:
        secret_name: minion-link-doppler
        service_name: minion-service-doppler
        link: |
          doppler.grpc_port: 8082
        addresses:
EOF
  #doppler
  kubectl get pods -n kubecf -o wide | grep doppler|awk '{print$6}' > temp_log
  while read -r ip
  do
     echo "        - ip: $ip" >> doppler_vms.yaml
  done < temp_log
  { cat doppler_vms.yaml 
  cat << EOF
      loggregator:
        secret_name: minion-link-loggregator
        service_name: minion-service-loggregator
        addresses:
EOF
  cat doppler_vms.yaml 
  cat >>"${minions_value_file}" << EOF
        link: |
          metron_endpoint.grpc_port: 3459
EOF
  } >> "${minions_value_file}" 

credentials_list=(
  loggregator.tls.doppler.ca_cert
  loggregator.tls.doppler.cert
  loggregator.tls.doppler.key
)
for (( i = 0 ; i < ${#credentials_list[@]} ; i++ )) do
    credential_type=$(echo "${credentials_list[$i]}" | cut -d "." -f 4 )
    credential_name="${credentials_list[$i]}"
    if [[ "X${credential_type}" != "X" ]]; then
      case ${credential_type} in 
      'ca_cert')
         type="ca"
         credential_name="loggregator.tls.ca_cert"
         ;;
      'cert')
         type="certificate"
         ;;
      'key')
         type="private_key"
         ;;
       *)
         echo "credentail type is false"
         ;;
       esac
    fi
    if [ "X${credential_name}" != "X" ] && [ "X${credential_type}" != "X" ]; then  
        credential_value=$(kubectl get secret var-loggregator-tls-doppler -n kubecf -o yaml 2> /dev/null | grep "^  ${type}:" | awk '{print $2}' | base64 --decode) 
        if [ "X${credential_value}" != "X" ]; then   
            echo "          ${credential_name}: |" >> "${minions_value_file}"
            for j in ${credential_value}; do
              if [[ "$j" =~ "-----"$ ]] || [ "$j" == "RSA" ] || [ "$j" == "PRIVATE" ]; then
                ${sed_cmd} "$ s/$/ $j/" "${minions_value_file}"
              else
                echo "            $j" >> "${minions_value_file}"
              fi
            done
        else
            echo "Warning: Not find , please manually update it in credentials part in file ${minions_value_file}."
        fi
    fi
done
  
  # cloud-controller
  { cat  << EOF
      cloud_controller:
        secret_name: minion-link-cloud-controller
        service_name: minion-service-cloud-controller
        link: |
          system_domain: "{{ .Values.system_domain }}"
          app_domains: []
        addresses:
EOF
  cat api_vms.yaml
  # cloud_controller_container_networking_info
  cat << EOF
      cloud_controller_container_networking_info:
        secret_name: minion-link-cloud-controller-container-networking-info
        service_name: minion-service-cloud-controller-container-networking-info
        link: |
          cc.internal_route_vip_range: "127.128.0.0/9"
        addresses:
EOF
  cat api_vms.yaml   
  #cf-network from diego-api
  cat >>"${minions_value_file}" << EOF
      cf_network:
        secret_name: minion-link-cf-network
        service_name: minion-service-cf-network
        link: |
          network: "10.255.0.0/16"
          subnet_prefix_length: 24
        addresses:
EOF
  cat diego_api.yaml
  } >> "${minions_value_file}"
}


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
echo "add Credentials ..."
AddCredentialsFun
echo "add Features ..."
AddFeaturesFun

echo "Complete. Please check output value file ${minions_value_file}."

#clean vm files
rm -f temp_log
rm -f nats_vms.yaml
rm -f doppler_vms.yaml
rm -f api_vms.yaml 
rm -f diego_api.yaml

