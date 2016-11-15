#!/bin/bash

echo "deprovisioning the azure agent..."
sudo chmod +s /usr/bin/screen
screen waagent -deprovision+user -force
sudo chmod -s /usr/bin/screen 
echo "deprovisioning over. VM ready to generalize and capture."