#!/usr/bin/env bash

NOTIFY_ID=19970920
ICON="$HOME/.config/i3/share/lightbulb_icon.png"

printf -v BACKLIGHT "%0.0f" $(xbacklight)
#notify-send -r ${NOTIFY_ID} -u low -a "Backlight" "${BACKLIGHT}%" --icon="${ICON}"
notify-send -u low -a "Backlight" "${BACKLIGHT}%" --icon="${ICON}"
