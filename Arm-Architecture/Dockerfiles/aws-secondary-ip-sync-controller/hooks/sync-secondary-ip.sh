#!/usr/bin/env bash
#set -xv

ARRAY_COUNT=`jq -r '. | length-1' $BINDING_CONTEXT_PATH`

touch /root/secondary-eni-ip-pod-mappings.txt 

function AddIPToEC2Instance() {
  echo -e "Pod ${resourceName} has been created, proceeding to associate the necessary secondary IPs with the EC2 instance \n"

  echo "Sleeping for 5 secs for interfaces to be up and running"

  sleep 5

  for macAddress in $(kubectl -n ${resourceNameSpace} get po ${resourceName} -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks-status}' | grep mac | awk '{print $NF}' | sed 's/"//g;s/,//g')
    do

      instance_region=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

      eni=$(aws --region $instance_region ec2 describe-network-interfaces \
      | grep -A 1 ${macAddress} | grep NetworkInterfaceId | \
      awk '{print $NF}' | sed 's/,//g;s/"//g')

      instance_id=$(aws --region $instance_region ec2 describe-network-interface-attribute \
       --network-interface-id ${eni} --attribute \
       attachment | jq -r .Attachment.InstanceId)      

      ip_address=$(kubectl -n ${resourceNameSpace} get po ${resourceName} -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks-status}' | grep -B 2 "$macAddress" | head -1 | awk '{print $NF}' | sed 's/"//g;s/,//g')
     
      echo -e "Adding $ip_address to instance ${instance_id} \n"

      aws --region $instance_region ec2 assign-private-ip-addresses \
      --network-interface-id $eni \
      --private-ip-addresses $ip_address \
      --allow-reassignment
 
      echo -e "Finished allocating IP $ip_address to instance ${instance_id} to ENI ${eni} \n"

      # Save the eni and IP info in state file, this will be used when POD is deleted

      echo "${resourceName} ${instance_region} $eni $ip_address" >> /root/secondary-eni-ip-pod-mappings.txt

  done
}

function  DetachIPFromEC2Instance() {
  echo "Pod ${resourceName} has been deleted, proceeding to dissociate the necessary secondary IPs from the EC2 instance"

  # Make grep to return complete line instead of individual words when used in FOR loop
  IFS=$'\n'

  # Retrieve POD IPs that was saved in the state file using the POD name
  for entry in $(grep ${resourceName} /root/secondary-eni-ip-pod-mappings.txt)
    do
        ip_address=$(echo ${entry} | awk '{print $NF}')

        eni=$(echo ${entry} | awk '{print $3}')

        region=$(echo ${entry} | awk '{print $2}')
       
        aws --region ${region} ec2 unassign-private-ip-addresses --network-interface-id \
        ${eni} --private-ip-addresses ${ip_address}

        echo "Secondary IP ${ip_address} entry for pod ${resourceName} has been removed from ${eni}"

  done

  IFS=""

  #Remove pod eni IP mapping entry in the state file
  sed -i "/${resourceName}/d" /root/secondary-eni-ip-pod-mappings.txt  

}

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- name: OnCreatePod
  apiVersion: v1
  kind: Pod
  executeHookOnEvent:
  - Added
  - Deleted
EOF
else
  # ignore Synchronization for simplicity
  type=$(jq -r '.[0].type' $BINDING_CONTEXT_PATH)
  if [[ $type == "Synchronization" ]] ; then
    echo Got Synchronization event
    exit 0
  fi

  for IND in $(seq 0 $ARRAY_COUNT)
    do
         resourceEvent=$(jq -r ".[$IND].watchEvent" $BINDING_CONTEXT_PATH)
         resourceName=$(jq -r ".[$IND].object.metadata.name" $BINDING_CONTEXT_PATH)
         resourceNameSpace=$(jq -r ".[$IND].object.metadata.namespace" $BINDING_CONTEXT_PATH)
         checkAnnotation=$(jq -r ".[$IND].object.metadata.annotations" $BINDING_CONTEXT_PATH | grep "k8s.v1.cni.cncf.io/networks")


        if [[ ! -z "${checkAnnotation}" ]];  then
            if [[ $resourceEvent == "Added" ]] ; then
                AddIPToEC2Instance
            else
                DetachIPFromEC2Instance
            fi
        fi
    done
fi