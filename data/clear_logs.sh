#!/bin/bash

echo "cleaning up..."
sudo rm /var/log/rkhunter.log.*
sudo rm /var/log/syslog.*
sudo rm /var/log/kern.log.*
echo "done."
