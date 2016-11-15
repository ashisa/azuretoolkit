#!/bin/bash

echo "deprovisioning the azure agent..."
sudo waagent -deprovision+user -force
echo "deprovisioning over. VM ready to generalize and capture."