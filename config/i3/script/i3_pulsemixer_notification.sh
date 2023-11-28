#!/usr/bin/env bash

# Pulseaudio volumes
VOLUMES=$(pulsemixer --get-volume)
L_VOLUME=$(echo ${VOLUMES} | awk '{print $1}')
R_VOLUME=$(echo ${VOLUMES} | awk '{print $2}')

# Mute label
if [ $(pulsemixer --get-mute) == 0 ]; then
    ICON="$HOME/.config/i3/share/volume_icon.png"
    CONTEXT="L:${L_VOLUME}% R:${R_VOLUME}%"
else
    ICON="$HOME/.config/i3/share/mute_icon.png"
    CONTEXT="MUTED (L:${L_VOLUME}% R:${R_VOLUME}%)"
fi

# Send notification
NOTIFY_SEND_VERSION=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
if (( $(echo ${NOTIFY_SEND_VERSION}) > 7 | bc -l )); then
    NOTIFY_ID=99709201
    notify-send -r ${NOTIFY_ID} -u low -a "Volume" "${CONTEXT}" --icon="${ICON}"
else
    notify-send low -a "Volume" "${CONTEXT}" --icon="${ICON}"
fi
