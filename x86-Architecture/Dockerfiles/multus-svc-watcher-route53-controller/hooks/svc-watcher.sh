#!/usr/bin/env bash
#set -xv

ARRAY_COUNT=`jq -r '. | length-1' $BINDING_CONTEXT_PATH`

region=`curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region`

function AddServiceNameToroute53() {

  route53ServiceName=$(kubectl -n ${resourceNameSpace} get pods ${resourceName} -o \
       jsonpath='{.metadata.annotations.route53-service-name}' | jq '.[] | .name' | sed 's/"//g')

  zoneID=$(aws --region ${region} route53 list-hosted-zones-by-name | grep -B 1 "${route53ServiceName}" \
       | grep Id | cut -d '/' -f 3 | sed 's/"//g;s/,//g')

  echo "Pod ${resourceName} has been created, proceeding to update the A record for the service in route53"

  echo "Sleeping for 5 secs for interfaces to be up and running"

  sleep 5

  multusNetDefinitionName=$(kubectl -n ${resourceNameSpace} get pods ${resourceName} -o \
  jsonpath='{.metadata.annotations.route53-service-name}' | jq .[] | grep -A 1 "$route53ServiceName" \
  | tail -1 | awk '{print $NF}' | sed 's/"//g')

  multusPodIP=$(kubectl -n ${resourceNameSpace} get pods ${resourceName} -o \
  jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks-status}' | \
  grep -A 3 "$multusNetDefinitionName" | tail -1 | sed 's/"//g;s/  *//g')

  serviceEntryTemplate='{
       "Comment": "Update the A record set",
       "Changes": [
         {
           "Action": "UPSERT",
           "ResourceRecordSet": {
             "Name": "DOMAIN",
             "Type": "A",
             "TTL": 30,
             "ResourceRecords": [
               {
                 "Value": "IP_ADDR"
               }
             ]
           }
         }
       ]
     }'    

  echo "Proceeding to create EPC DNS entry for ${route53ServiceName}"

  echo $serviceEntryTemplate | sed "s/DOMAIN/${route53ServiceName}./g;s/IP_ADDR/${multusPodIP}/g" \
   | jq . > /tmp/${resourceName}.json   

  aws --region ${region} route53 change-resource-record-sets --hosted-zone-id ${zoneID} \
  --change-batch file:///tmp/${resourceName}.json

  rm -rf /tmp/${resourceName}.json

  echo "Record ${route53ServiceName} has been mapped to ${multusPodIP} in route53"

  localRoute53mapping="${resourceName} ${route53ServiceName} ${multusPodIP} ${zoneID}"

  echo ${localRoute53mapping} >> /route53_service_id_record.txt
}

function  RemoveServiceNameFromroute53() {
  echo "Pod ${resourceName} has been deleted, proceeding to remove the A record for the service in route53"

  deleteTemplate='{
     "Comment": "Delete single record set",
     "Changes": [
         {
             "Action": "DELETE",
             "ResourceRecordSet": {
                 "Name": "DOMAIN",
                 "Type": "A",
                 "TTL": 30,
                 "ResourceRecords": [
                     {
                         "Value": "IP_ADDR"
                     }
                 ]                
             }
         }
     ]
    }'

  IFS=$'\n'

  for record in $(grep ${resourceName} /route53_service_id_record.txt)
   do
      route53ServiceName=$(echo ${record} | awk '{print $2}')

      route53IPentry=$(echo ${record} | awk '{print $3}')

      zoneID=$(echo ${record} | awk '{print $NF}')
      
      echo $deleteTemplate | sed "s/DOMAIN/${route53ServiceName}./g;s/IP_ADDR/${route53IPentry}/g" \
       | jq . > /tmp/${resourceName}-deletion.json
    
      aws --region ${region} route53 change-resource-record-sets --hosted-zone-id ${zoneID} \
      --change-batch file:///tmp/${resourceName}-deletion.json 
    
      #Remove route53 service mapping entry in the records file
      sed -i "/${route53IPentry}/d" /route53_service_id_record.txt
      echo "${route53IPentry} entry for POD ${resourceName} for DNS ${route53ServiceName} in route53 has been removed"     
  done

  IFS=""
}

#function RemoveMultusIPFromEC2() {
#  #statements
#}

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
         checkAnnotation=$(jq -r ".[$IND].object.metadata.annotations" $BINDING_CONTEXT_PATH | grep -w route53-service-name)


               if [[ ! -z "${checkAnnotation}" ]];  then
                    if [[ $resourceEvent == "Added" ]] ; then
                        AddServiceNameToroute53
                    else
                        RemoveServiceNameFromroute53
                    fi
               fi
    done
fi