#!/usr/bin/env bash

# Dunst
NOTIFY_ID=99709201

# Pulseaudio volumes
VOLUMES=$(pulsemixer --get-volume)
L_VOLUME=$(echo $VOLUMES | awk '{print $1}')
R_VOLUME=$(echo $VOLUMES | awk '{print $2}')

# Mute label
if [ $(pulsemixer --get-mute) == 0 ]; then
    CONTEXT="L:$L_VOLUME% R:$R_VOLUME%"
    ICON="~/.config/i3/share/volume_icon.png"
else
    ICON="~/.config/i3/share/mute_icon.png"
    CONTEXT="MUTED (L:$L_VOLUME% R:$R_VOLUME%)"
fi

dunstify -r $NOTIFY_ID --urgency low --appname="Volume" --icon="$ICON" "$CONTEXT"
