#!/bin/bash

echo "deprovisioning the azure agent..."
(sleep 10; sudo /usr/sbin/waagent -deprovision -force; sudo shutdown -h) &:
echo "deprovisioning over. VM ready to generalize and capture."