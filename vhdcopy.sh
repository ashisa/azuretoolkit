#!/bin/bash

sourcesub=$1
targetsub=$2
sourceurl=$3
sourcesa=`echo $3 |awk -F "/" '{ print $3}' |awk -F "." '{print $1}'`
sourcecnt=`echo $3 |awk -F "/" '{ print $4}'`
if [ "$4" != "" ];
then
   targetsa=$4
else
   targetsa=new${sourcesa}
fi
if [ "$5" != "" ];
then
   targetcnt=$5
else
   targetcnt=${sourcecnt}
fi
sourceblob=`echo $3 |awk -F "/" '{print $5}'`

echo "Fetching resource group information..."
sourcerg=`azure storage account list -s ${sourcesub} --json  | jq " .[] | select(.name == \"${sourcesa}\").resourceGroup" |sed s/\"//g`
sourceloc=`azure storage account list -s ${sourcesub} --json  | jq " .[] | select(.name == \"${sourcesa}\").location" |sed s/\"//g`
targetrg=new${sourcerg}

echo "Verifying target storage account..."
status=`azure storage account list -s ${targetsub} --json | jq " .[] | select(.name == \"${targetsa}\").name" |sed s/\"//g`
if [ \"${targetsa}\" != \"${status}\" ];
then
   echo "Source storage account not found in target subscription."
   echo "Creating storage account..."
   azure group create ${targetrg} -l ${sourceloc}
   azure storage account create ${targetsa} -l ${sourceloc} -g ${targetrg} -s ${targetsub}
fi

targetrg=`azure storage account list -s ${targetsub} --json  | jq " .[] | select(.name == \"${targetsa}\").resourceGroup" |sed s/\"//g`

echo "Fetching connection strings..."
sourceconnstr=`azure storage account connectionstring show ${sourcesa} -g ${sourcerg} -s ${sourcesub} --json | jq " .[] " |sed s/\"//g`
targetconnstr=`azure storage account connectionstring show ${targetsa} -g ${targetrg} -s ${targetsub} --json | jq " .[] " |sed s/\"//g`

echo "Verifying source container..."
status=`azure storage container list -c ${sourceconnstr} --json | jq " .[] | select(.name == \"${sourcecnt}\").name" |sed s/\"//g`
if [ \"${sourcecnt}\" != \"${status}\" ];
then
   echo "Source container not found in storage account ${sourcesa}. Please verify if source container exists."
   exit
fi

echo "Verifying target container..."
status=`azure storage container list -c ${targetconnstr} --json | jq " .[] | select(.name == \"${targetcnt}\").name" |sed s/\"//g`
if [ \"${targetcnt}\" != \"${status}\" ];
then
   echo "Target container not found in storage account ${targetsa}."
   echo "Creating target container..."
   azure storage container create ${targetcnt} -p Blob -c ${targetconnstr}
fi

echo "Verifying source blob..."
blobstatus=`azure storage blob list ${sourcecnt} -c ${sourceconnstr} --json | jq " .[] | select(.name == \"${sourceblob}\").name" |sed s/\"//g`
if [ \"${sourceblob}\" != \"${blobstatus}\" ];
then
   echo "Source blob not found in storage container ${sourcecnt}. Please verify the source blob exists"
   exit
fi

echo "Copying ${sourceblob} from ${sourcesa}\\${sourcecnt} to ${targetsa}\\${targetcnt}..."
echo "Copying started. Status:"
azure storage blob copy start --source-container ${sourcecnt} --source-blob ${sourceblob}  -c ${sourceconnstr} --dest-connection-string ${targetconnstr} --dest-container ${targetcnt} --json 
