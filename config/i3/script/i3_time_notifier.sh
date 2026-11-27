#!/usr/bin/env bash

# Run from cron, e.g. every 15 minutes (`crontab -e`):
#   */15 * * * * /home/jordan/.config/i3/script/i3_time_notifier.sh
# The D-Bus address and DISPLAY of every running i3 session are taken from its i3
# process, so the notification shows in the dunst of each i3 session, whatever display
# (:0, :1 ...) it is on. Sessions sharing one D-Bus bus (and so one dunst) get it once.
# Nothing is shown while i3 is not running.
source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"

ICON="$HOME/.config/i3/share/64x64/notification.png"

# Send notification (run inside one i3 session's environment)
notify_time () {
    local notify_send_version
    notify_send_version=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
    if (( notify_send_version > 7 )); then
        local notify_id=97092019
        notify-send -t 1500 -r "$notify_id" -a "Current Time" "$(date +"%R")" --icon="$ICON"
    else
        notify-send -t 1500 -a "Current Time" "$(date +"%R")" --icon="$ICON"
    fi
}

for_each_i3_session --unique-dbus notify_time || exit 1
