#!/bin/bash

echo "deprovisioning the azure agent..."
echo '* * * * * /tmp/deprovision.sh >/tmp/deprovision.log 2>&1' >/tmp/cronjob.tmp
echo 'sleep 120; sudo waagent -deprovision+user -force; crontab -r' >/tmp/deprovision.sh
chmod a+x /tmp/deprovision.sh
crontab /tmp/cronjob.tmp
echo "deprovisioning over. VM ready to generalize and capture."