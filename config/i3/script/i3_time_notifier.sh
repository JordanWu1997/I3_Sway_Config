#!/usr/bin/env bash

# NOTE: XDG_RUNTIME_DIR variable MUST be added in crontab task for notify-send
# Example: */15 * * * * XDG_RUNTIME_DIR=/run/user/$(id -u) i3_time_notifier.sh

# Send notification
NOTIFY_SEND_VERSION=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
if (( $(echo ${NOTIFY_SEND_VERSION}) > 7 | bc -l )); then
    NOTIFY_ID=97092019
    notify-send -t 1500 -r ${NOTIFY_ID} -a "Current Time" $(date +"%R")
else
    notify-send -t 1500 -a "Current Time" $(date +"%R")
fi
