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
    echo "   -t"
    echo "              The prefix name for diego cell"
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
    -t)
    prefix_name=$1
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

function AddPropertiesFun(){
  cat >>"${minions_value_file}" <<EOF
properties:
  ${diego_cell_name}:
    rep:
      diego:
        rep:
          advertise_domain: "${diego_cell_domain}"
EOF
}

function AddCredentialsFun(){
    echo "credentials:" >> "${minions_value_file}"
    credential_value=$(kubectl get secret var-uaa-ssl -n kubecf -o yaml 2> /dev/null | grep "^  ca:" | awk '{print $2}' | base64 --decode)
    if [ "X${credential_value}" != "X" ]; then
        echo "  uaa_ssl.ca: |" >> "${minions_value_file}"
        for j in ${credential_value}; do
          if [[ "$j" =~ "-----"$ ]] || [ "$j" == "RSA" ] || [ "$j" == "PRIVATE" ]; then
            ${sed_cmd} "$ s/$/ $j/" "${minions_value_file}"
          else
            echo "    $j" >> "${minions_value_file}"
          fi
        done
    else
        echo "Warning: Not find uaa_ssl, please manually update it in credentials part in file ${minions_value_file}."
    fi

    credential_value=$(kubectl get secret var-uaa-clients-tcp-emitter-secret -n kubecf -o yaml 2> /dev/null | grep "^  password:" | awk '{print $2}' | base64 --decode)
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
        name: singleton-blobstore
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

ca_list=(
  service_cf_internal_ca
  application_ca
  loggregator_ca
  metric_scraper_ca
  silk_ca
  network_policy_ca
  cf_app_sd_ca
  nats_ca
)

types=(
    certificate
    private_key
)



function AddCAcertsFun(){
  echo "    control_plane_ca:" >> "${minions_value_file}"
  for (( i = 0 ; i < ${#ca_list[@]} ; i++ )) do
    echo "      ${ca_list[$i]}:" >> "${minions_value_file}"
    ca_name=${ca_list[$i]}
    name="${ca_name//_/-}"
    echo "        name: ${name}" >> "${minions_value_file}"
    for (( k =0; k < ${#types[@]}; k++ )) do
      value=$(kubectl get secret var-"${name}" -n kubecf -o yaml 2> /dev/null | grep "^  ${types[$k]}:" | awk '{print $2}' | base64 --decode)
      if [ "X${value}" != "X" ]; then
        echo "        ${types[$k]}: |" >> "${minions_value_file}"
        for j in ${value}; do
          if [[ "$j" =~ "-----"$ ]] || [ "$j" == "RSA" ] || [ "$j" == "PRIVATE" ]; then
            ${sed_cmd} "$ s/$/ $j/" "${minions_value_file}"
          else
            echo "          $j" >> "${minions_value_file}"
          fi
        done
      else
        echo "Warning: Not find ${ca_list[$i]}, please manually update it in credentials part in file ${minions_value_file}."
      fi
    done
  done
}

function AddInlinesFun(){
  cat >>"${minions_value_file}" << EOF
operations:
  inline:
  - type: replace
    path: /instance_groups/name=diego-cell/name
    value: ${diego_cell_name}
  - type: replace
    path: /instance_groups/name=${diego_cell_name}/env?/bosh/agent/settings/preRenderOps/instanceGroup?
    value:
    - type: replace
      path: /instance_groups/name=${diego_cell_name}/jobs/name=silk-daemon/properties/quarks/consumes/vpa/instances?
      value:
      - address: diego-cell-0
    - type: replace
      path: /instance_groups/name=${diego_cell_name}/jobs/name=silk-cni/properties/quarks/consumes/vpa/instances?
      value:
      - address: diego-cell-0
  - type: replace
    path: /addons/name=bosh-dns-aliases/jobs/name=bosh-dns-aliases/properties/aliases
    value:
    - domain: '_.${diego_cell_domain}'
      targets:
      - query: '_'
        instance_group: ${diego_cell_name}
        deployment: cf
        network: default
        domain: bosh
  - type: replace
    path: /variables/name=diego_rep_agent_v2/options/common_name?
    value: ${diego_cell_domain}
  - type: replace
    path: /variables/name=diego_rep_agent_v2/options/alternative_names?
    value:
    - "*.${diego_cell_domain}"
    - ${diego_cell_domain}
    - 127.0.0.1
    - localhost  
EOF

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

# Check prefix_name
diego_cell_name="diego-cell"
diego_cell_domain="cell.service.cf.internal"
if [[ "X$prefix_name" != "X" ]]; then
   diego_cell_name="${prefix_name}-diego-cell"
   diego_cell_domain="${prefix_name}.cell.service.cf.internal"
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
echo "add Properties..."
AddPropertiesFun
echo "add Credentials ..."
AddCredentialsFun
echo "add Features ..."
AddFeaturesFun
echo "add CA certs ..."
AddCAcertsFun
echo "add inlines..."
AddInlinesFun

echo "Complete. Please check output value file ${minions_value_file}."

#clean vm files
rm -f temp_log
rm -f nats_vms.yaml
rm -f doppler_vms.yaml
rm -f api_vms.yaml 
rm -f diego_api.yaml

