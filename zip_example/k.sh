#!/bin/sh
# Quickly copy & paste this into SSH during grace period and press ENTER:
# /mnt/us/extensions/TRMNL_KINDLE/k.sh
echo "Identifying TRMNL process..."
PID=$(ps aux | grep TRMNL | grep -v grep | awk '{print $2}')
echo "Killing PID ${PID}..."
kill $PID
