#!/usr/bin/env bash

scriptname=$(basename "${0}")
input_value_file="values.yaml"
minions_value_file="minions-values.yaml"

#
# Usage statement
#
usage() {
    echo
    echo "Usage: $scriptname [OPTIONS]"
    echo
    echo "   -i"
    echo "              The provided input value file"
    echo "   -o"
    echo "              The output value file for minions cluster"
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
    -i)
    input_value_file=$1
    shift
    ;;
    -o)
    minions_value_file=$1
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
          placement_tags: ['minions-1']
EOF
}

function AddCredentialsFun(){
  echo "credentials:" >> "${minions_value_file}"
  for (( i = 0 ; i < ${#credentials_list[@]} ; i++ )) do
    credential_type=$(echo "${credentials_list[$i]}" | cut -d "." -f 2)
    credential_name=$(echo "${credentials_list[$i]}" | cut -d "." -f 1 | sed "s/_/-/g" )

    if [ "X${credential_name}" != "X" ] && [ "X${credential_type}" != "X" ]; then
      credential_value=$(kubectl get secret var-"${credential_name}" -n kubecf -o yaml 2> /dev/null | grep "^  ${credential_type}:" | awk '{print $2}' | base64 -d)
      if [ "X${credential_value}" != "X" ]; then
        echo "  ${credentials_list[$i]}: |" >> "${minions_value_file}"
        for j in ${credential_value}; do
          if [[ "$j" =~ "-----"$ ]] || [ "$j" == "RSA" ] || [ "$j" == "PRIVATE" ]; then
            sed -i "$ s/$/ $j/" "${minions_value_file}"
          else
            echo "    $j" >> "${minions_value_file}"
          fi
        done
      else
        echo "Warning: Not find ${credentials_list[$i]}, please manually update it in credentials part in file ${minions_value_file}."
      fi
    fi
  done

  credential_value=$(kubectl get secret var-uaa-clients-tcp-emitter-secret -n kubecf -o yaml | grep "^  password:" | awk '{print $2}' | base64 -d)
  if [ "X${credential_value}" != "X" ]; then
    echo "  uaa_clients_tcp_emitter_secret: ${credential_value}" >> "${minions_value_file}"
  else
    echo "Warning: Not find uaa_clients_tcp_emitter_secret, please manually update it in credentials part in file ${minions_value_file}."
  fi
}

function AddInlineFun(){
    cat >>"${minions_value_file}" <<EOF
  inline:
  # To deploy a cell
  - type: remove
    path: /instance_groups/name=adapter
  - type: remove
    path: /instance_groups/name=api
  - type: remove
    path: /instance_groups/name=auctioneer
  - type: remove
    path: /instance_groups/name=cc-worker
  - type: remove
    path: /instance_groups/name=diego-api
  - type: remove
    path: /instance_groups/name=doppler
  - type: remove
    path: /instance_groups/name=log-api
  - type: remove
    path: /instance_groups/name=log-cache
  - type: remove
    path: /instance_groups/name=nats
  - type: remove
    path: /instance_groups/name=router
  - type: remove
    path: /instance_groups/name=scheduler
  - type: remove
    path: /instance_groups/name=singleton-blobstore
  - type: remove
    path: /instance_groups/name=uaa
  - type: remove
    path: /instance_groups/name=rotate-cc-database-key
  - type: remove
    path: /instance_groups/name=smoke-tests?
  - type: remove
    path: /instance_groups/name=acceptance-tests?
  - type: remove
    path: /instance_groups/name=sync-integration-tests?
  - type: replace
    path: /instance_groups/name=diego-cell/jobs/name=route_emitter/consumes?
    value:
      nats: {from: nats}
      nats-tls: {from: nats-tls}
      routing_api: {from: routing_api}
  - type: replace
    path: /instance_groups/name=diego-cell/jobs/name=loggr-udp-forwarder/consumes?
    value:
      cloud_controller: {from: cloud_controller}
  - type: replace
    path: /addons/name=prom_scraper/jobs/name=prom_scraper/consumes?
    value:
      loggregator: {from: loggregator}
  - type: replace
    path: /addons/name=loggregator_agent/jobs/name=loggregator_agent/consumes?
    value:
      doppler: {from: doppler}
EOF
}

function AddValueFun(){
  i=$1
  if [ "$i" == "inline" ]; then
    echo "add inline config to value file."
    AddInlineFun
  elif [ "$i" == "credentials" ]; then
    echo "add credentials config to value file."
    AddCredentialsFun
  elif [ "$i" == "properties" ]; then
    echo "add properties config to value file."
    AddPropertiesFun 
  else
    echo "Warning: No new value file."
  fi
}

#Add required properties, credentials, inline into value.yaml
##find properties, credentials, inline's line number in value.yaml
properties_line=$(grep -n "^properties: {}" "${input_value_file}" | cut -d ":" -f 1)
credentials_line=$(grep -n "^credentials: {}" "${input_value_file}" | cut -d ":" -f 1)
inline_line=$(grep -n "^  inline: \[\]" "${input_value_file}" | cut -d ":" -f 1)

if [ "${credentials_line}" -gt "${properties_line}" ]; then
  section0=("properties" "${properties_line}")
  section1=("credentials" "${credentials_line}")
  if [ "${inline_line}" -gt "${credentials_line}" ]; then
    section2=("inline" "${inline_line}")
  elif [ "${inline_line}" -lt "${credentials_line}" ] && [ "${inline_line}" -gt "${properties_line}" ] ; then
    section1=("inline" "${inline_line}")
    section2=("credentials" "${credentials_line}")
  else
    section0=("inline" "${inline_line}")
    section1=("properties" "${properties_line}")
    section2=("credentials" "${credentials_line}")
  fi
else
  section0=("credentials" "${credentials_line}")
  section1=("properties" "${properties_line}")
  if [ "${inline_line}" -gt "${properties_line}" ]; then
    section2=("inline" "${inline_line}")
  elif [ "${inline_line}" -lt "${properties_line}" ] && [ "${inline_line}" -gt "${credentials_line}" ] ; then
    section1=("inline" "${inline_line}")
    section2=("properties" "${properties_line}")
  else
    section0=("inline" "${inline_line}")
    section1=("credentials" "${credentials_line}")
    section2=("properties" "${properties_line}")
  fi
fi

##insert required properties, credentials, inline into value.yaml
sed -n "1,$((section0[1]-1))p" "${input_value_file}" >> "${minions_value_file}"
AddValueFun "${section0[0]}"
sed -n "$((section0[1]+1)),$((section1[1]-1))p" "${input_value_file}" >> "${minions_value_file}"
AddValueFun "${section1[0]}"
sed -n "$((section1[1]+1)),$((section2[1]-1))p" "${input_value_file}" >> "${minions_value_file}"
AddValueFun "${section2[0]}"
sed -n "$((section2[1]+1)),\$p" "${input_value_file}" >> "${minions_value_file}"

#update system_domain
system_domain=$(kubectl get secret var-system-domain -n kubecf -o yaml | grep "^  value:" | awk '{print $2}' | base64 -d)
if [ "X$system_domain" == "X" ]; then
  echo "Warning: Not find system domain, please manually update it in file ${minions_value_file}."
else
  sed -i "s/system_domain: ~/system_domain: $system_domain/g" "${minions_value_file}"
fi

#update embedded_database to be false
echo "set embedded_database enabled: false"
for num in $(grep -n "^  embedded_database:" "${minions_value_file}" | cut -d ":" -f 1 | xargs); do
  sed -i "$((num+1))s/enabled: true/enabled: false/" "${minions_value_file}"
done

#update routing_api to be false
echo "set routing_api enabled: false"
for num in $(grep -n "^  routing_api:" "${minions_value_file}" | cut -d ":" -f 1 | xargs); do
  sed -i "$((num+1))s/enabled: true/enabled: false/" "${minions_value_file}"
done

#update credhub to be false
echo "set credhub enabled: false"
for num in $(grep -n "^  credhub:" "${minions_value_file}" | cut -d ":" -f 1 | xargs); do
  sed -i "$((num+1))s/enabled: true/enabled: false/" "${minions_value_file}"
done

