#!/bin/bash

echo "deprovisioning the azure agent..."
echo 'sudo waagent -deprovision+user -force; sudo shutdown -h now' >/tmp/deprovision.sh
chmod a+x /tmp/deprovision.sh
echo "deprovisioning over. VM ready to generalize and capture."