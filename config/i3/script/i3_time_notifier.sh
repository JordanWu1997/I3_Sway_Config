#!/usr/bin/env bash

# Run from cron, e.g. every 15 minutes (`crontab -e`):
#   */15 * * * * /home/jordan/.config/i3/script/i3_time_notifier.sh
# The i3 session's D-Bus address and DISPLAY are taken from the running i3, so the
# notification shows in the dunst of the i3 session, whatever display (:0, :1 ...)
# it is on. Nothing is shown while i3 is not running.
source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"
import_i3_session_env || exit 1

# Send notification
ICON="$HOME/.config/i3/share/64x64/notification.png"
NOTIFY_SEND_VERSION=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
if (( $(echo ${NOTIFY_SEND_VERSION}) > 7 | bc -l )); then
    NOTIFY_ID=97092019
    notify-send -t 1500 -r ${NOTIFY_ID} -a "Current Time" "$(date +"%R")" --icon="$ICON"
else
    notify-send -t 1500 -a "Current Time" "$(date +"%R")" --icon="$ICON"
fi
