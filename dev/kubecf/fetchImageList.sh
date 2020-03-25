#!/bin/bash

set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <HELM_TEMPLATE_FILE> <VALUES_FILE>"
  echo ""
  echo "Example: $0 output.yaml values.yaml"
  exit 1
fi

manifestIdentifyString="# Source: kubecf/templates/cf_deployment.yaml"
variableIdentifyString="# Source: kubecf/templates/implicit_vars.yaml"
qjobName="QuarksJob"

# Count the number of yaml blocks
yamlFileCount=$(grep -c "# Source: kubecf/templates/" "$1")
yamlFileCount=$((yamlFileCount - 1))

# Fetch manifest file
for fileIndex in $(seq 0 "$yamlFileCount")
do
    yamlOutput=$(yq r -d"$fileIndex" "$1")
    if [[ $yamlOutput =~ $manifestIdentifyString ]]
    then
        yq r -d"$fileIndex" "$1" data.manifest > manifest.yaml
    fi
done

## Interpolate ops files
for fileIndex in $(seq 0 "$yamlFileCount")
do
	yamlOutput=$(yq r -d"$fileIndex" "$1" data.ops)
    if [ -n "$yamlOutput" ]
    then
        yq r -d"$fileIndex" "$1" data.ops > ops"$fileIndex".yaml
        bosh interpolate manifest.yaml --ops-file ops"$fileIndex".yaml > manifest"$fileIndex".yaml
        cp manifest"$fileIndex".yaml manifest.yaml
        
        rm ops"$fileIndex".yaml
        rm manifest"$fileIndex".yaml
    fi
done

## Interpolate implicit variables
for fileIndex in $(seq 0 "$yamlFileCount")
do
	yamlOutput=$(yq r -d"$fileIndex" "$1")
    if [[ $yamlOutput =~ $variableIdentifyString ]]
    then
        key=$(yq r -d"$fileIndex" "$1" metadata.name)
        key=$(cut -d '-' -f2- <<< "$key")
        key=${key//-/_}
        value=$(yq r -d"$fileIndex" "$1" stringData.value)
        if [ -n "$value" ]
        then
            bosh interpolate manifest.yaml -v "$key"="$value" > manifest"$fileIndex".yaml
            cp manifest"$fileIndex".yaml manifest.yaml
            
            rm manifest"$fileIndex".yaml
        fi
    fi
done

# Print image info from kube manifest
imageCount=$(yq r manifest.yaml --length releases)
for imageIndex in $(seq 0 "$imageCount")
do
    value=$(yq r manifest.yaml releases["$imageIndex"].stemcell)
    if [ -n "$value" ]
    then 
        imageName=$(yq r manifest.yaml releases["$imageIndex"].name)
        imageUrl=$(yq r manifest.yaml releases["$imageIndex"].url)
        imageOS=$(yq r manifest.yaml releases["$imageIndex"].stemcell.os)
        imageStemcellVersion=$(yq r manifest.yaml releases["$imageIndex"].stemcell.version)
        imageVersion=$(yq r manifest.yaml releases["$imageIndex"].version)
    
        imageElement="${imageUrl}/${imageName}:${imageOS}-${imageStemcellVersion}-${imageVersion}"
        echo "$imageElement"
    fi
done

# Print image info from QuarksJob
for fileIndex in $(seq 0 "$yamlFileCount")
do
    data=$(yq r -d"$fileIndex" "$1" kind)
    if [[ $data == "$qjobName" ]]
    then
        containersCount=$(yq r -d"$fileIndex" "$1" --length spec.template.spec.template.spec.containers)
        containersCount=$((containersCount - 1))
        for containerIndex in $(seq 0 "$containersCount")
        do 
            imageName=$(yq r -d"$fileIndex" "$1" spec.template.spec.template.spec.containers["$containerIndex"].image)
            echo "$imageName"
        done
    fi
done
