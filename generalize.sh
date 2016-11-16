#!/bin/bash

echo "deprovisioning the azure agent..."
echo '* * * * * /tmp/deprovision.sh >/tmp/deprovision.log 2>&1' >/tmp/cronjob.tmp
echo 'sudo waagent -deprovision+user -force; crontab -r; sudo shutdown -h now' >/tmp/deprovision.sh
chmod a+x /tmp/deprovision.sh
crontab /tmp/cronjob.tmp
echo "deprovisioning over. VM ready to generalize and capture."