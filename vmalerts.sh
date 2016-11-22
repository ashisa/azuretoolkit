#!/bin/bash

emailID=$1
metric=$2
threshold=$3
rgname=$4
vmname=$5

if [ "${metric}" == "cpu" ]
then
   metricname="Percentage CPU"
fi

if [ "${metric}" == "memory" ]
then
   metricname=\\Memory\\PercentUsedMemory
echo ${metricname}
fi

if [ "$4" == "" ]
then
   echo "Setting alerts based on ${metric} on all VMs..."
   for i in `azure group list --json | jq -r '.[] | .location + "#" + .name'`;
   do
      rgname=`echo $i |awk -F# '{print $2}'`
      location=`echo $i |awk -F# '{print $1}'`
      echo Looking for VMs  under $rgname...
      for j in `azure vm list ${rgname} --json | jq -r '.[] | .name + "#" + .id'`
      do
         vmname=`echo $j |awk -F# '{print $1}'`
         vmid=`echo $j |awk -F# '{print $2}'`
         if [ "${metric}" == "memory" ]
         then
            echo "Checking/Enabling diagnostics on the VM to enable alerts based on memory usage..." 
            diagstatus=`azure vm get-instance-view ${rgname} ${vmname} --json | jq -s ".[].resources[].virtualMachineExtensionType | contains(\"Diagnostic\")" |grep true`
            if [ "${diagstatus}" != "true" ]
            then
               azure vm enable-diag ${rgname} ${vmname}
            fi
         fi
            azure insights alerts rule metric set ${vmname}-${metric}-rule ${location} ${rgname} 00:15:00 GreaterThan ${threshold} ${vmid} "${metricname}" Average -z "[{\"customEmails\":[\"${emailID}\"],\"sendToServiceOwners\":\"true\",\"type\":\"Microsoft.Azure.Management.Insights.Models.RuleEmailAction\"}]"
      done
   done
fi

