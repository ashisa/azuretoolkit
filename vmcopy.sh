#!/bin/bash

sourcesub=$1
targetsub=$2
targetlocation=$3
sourcerg=$4
sourcevm=$5
targetrg=$6
targetvm=$7
vnetprefix="10.0.0.0/24"
subnetprefix="10.0.0.0/24"

datetime=`date +%m%_d`

echo "Registering Microsoft.Network and Microsoft.Network providers with the target subscription..."
azure provider register Microsoft.Network -s ${targetsub} --json
azure provider register Microsoft.Compute -s ${targetsub} --json

echo "Fetching information about source VM..."
vminfo=`azure vm get-instance-view ${sourcerg} ${sourcevm} --subscription ${sourcesub} --json | jq -s -r ' .[] | .id + "#" + .location + "#" + .hardwareProfile.vmSize + "#" + .storageProfile.osDisk.osType + "#" + .storageProfile.osDisk.vhd.uri '`

vmid=`echo $vminfo | awk -F "#" '{print $1}'`
vmlocation=`echo $vminfo | awk -F "#" '{print $2}'`
vmsize=`echo $vminfo | awk -F "#" '{print $3}'`
vmos=`echo $vminfo | awk -F "#" '{print $4}'`
vmvhd=`echo $vminfo | awk -F "#" '{print $5}'`
sourcesa=`echo $vmvhd | awk -F "/" '{print $3}' |awk -F "." '{print $1}'`
sourcecnt=`echo $vmvhd | awk -F "/" '{print $4}'`
sourcevhd=`echo $vmvhd | awk -F "/" '{print $5}'`

echo "Determining information to copy the VM to target subscription.."
if [ "${targetrg}" == "" ];
then
   targetrg=${sourcerg}${datetime}
fi

if [ "${targetvm}" == "" ];
then
   targetvm=${sourcevm}${datetime}
fi

if [ "${targetlocation}" == "" ];
then
   targetlocation=${vmlocation}
fi

targetsa=`echo ${targetrg}${sourcesa} |cut -c1-23`
targetcnt=${sourcecnt}
targetvhd=`echo ${sourcevhd/${sourcevm}/${targetvm}}`

#check & create resource group/target storage account
echo "Creating target resources..."
echo "Creating target resource group ${targetrg}..."
status=`azure group list --subscription ${targetsub} --json | jq -r ' .[] | select(.name == "${targetrg}").name'`
if [ \"${targetrg}\" == \"${status}\" ]
then
   azure group create ${targetrg} ${targetlocation} --subscription ${targetsub}
   if [ "$?" == "1" ]
   then
      echo "Cannot create resource group. Please rectify the error mentioned above."
      exit
   fi
fi

echo "Creating target storage account ${targetsa}..."
status=`azure storage account list -s ${targetsub} --json | jq " .[] | select(.name == \"${targetsa}\").name" |sed s/\"//g`
if [ \"${targetsa}\" != \"${status}\" ];
then
   azure storage account create ${targetsa} -l ${targetlocation} --kind Storage --sku-name LRS -g ${targetrg} -s ${targetsub}
   if [ "$?" == "1" ]
   then
      echo "Cannot create storage account. Please rectify the error mentioned above."
      exit
   fi
fi

#get connection strings from source/target storage accounts
sourceconnstr=`azure storage account connectionstring show ${sourcesa} -g ${sourcerg} -s ${sourcesub} --json |jq -r '.[]'`
targetconnstr=`azure storage account connectionstring show ${targetsa} -g ${targetrg} -s ${targetsub} --json |jq -r '.[]'`

#check and create target container
echo "Verifying/creating target container..."
status=`azure storage container list -c ${targetconnstr} --json | jq " .[] | select(.name == \"${targetcnt}\").name" |sed s/\"//g`
if [ \"${targetcnt}\" != \"${status}\" ];
then
   echo "Target container not found in storage account ${targetsa}."
   echo "Creating target container..."
   azure storage container create ${targetcnt} -p Blob -c ${targetconnstr}
   if [ "$?" == "1" ]
   then
      echo "Cannot create container. Please rectify the error mentioned above."
      exit
   fi
fi

#start copying the source blob to target storage account
echo "Starting the copy operation..."
date
azure storage blob copy start --source-container ${sourcecnt} --source-blob ${sourcevhd}  -c ${sourceconnstr} --dest-connection-string ${targetconnstr} --dest-container ${targetcnt} --dest-blob ${targetvhd}
if [ "$?" == "1" ]
then
   echo "Copying operation could not be started. Please rectify the error mentioned above."
   exit
fi

echo -n "Checking copy progress..."
status=`azure storage blob copy show ${targetcnt} ${targetvhd} -c ${targetconnstr} --json | jq -s -r ' .[] | .copy.status'`
while [ "${status}" != "success" ]
do
   sleep 3
   echo -n .
   status=`azure storage blob copy show ${targetcnt} ${targetvhd} -c ${targetconnstr} --json | jq -s -r ' .[] | .copy.status'`
   if [ "${status}" == "failed" ]
   then
      echo 
      echo "Copy operation failed. Please ensure that the source VM is shut down."
      echo
      exit
   fi
done

#time to build a vm from the VHD
echo .
date
echo "Creating VM based on the VHD now..."
azure vm create ${targetrg} ${targetvm} ${targetlocation} ${vmos} -o ${targetsa} -d https://${targetsa}.blob.core.windows.net/${targetcnt}/${targetvhd} -f ${targetvm}nic -F ${targetrg}vnet -P ${vnetprefix} -j ${targetrg}subnet -k ${subnetprefix} -r ${targetrg}avset -z ${vmsize} -i ${targetvm}ip -w ${targetvm}${datetime} -u usera -p password@${datetime} -s ${targetsub}

if [ "$?" == "1" ]
then
   echo "VM creation failed. Please check above the errors and take corrective actions."
   exit
else
   echo "VM creation succeeded."
   echo
fi
