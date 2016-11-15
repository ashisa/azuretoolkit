#!/bin/bash

echo "deprovisioning the azure agent..."
/usr/bin/python3 /usr/sbin/waagent -deprovision+user -force
echo "deprovisioning over. VM ready to generalize and capture."