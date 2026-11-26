#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Choose the default audio output (sink) or input (source) with rofi
###########################################################

# Requirements:
#   pactl (pulseaudio-utils, also works with pipewire-pulse) rofi

# Usage: i3_audio_device_operator.sh [sink|source]
#   Streams that are playing (sink) or recording (source) move to the new device too,
#   so the switch takes effect right away instead of only for new streams.

ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"

show_help_message () {
    echo "Usage:"
    echo "  i3_audio_device_operator.sh [sink|source]"
    echo ""
    echo "OPTIONS"
    echo "  [sink]: select default audio output (speaker, headphones, HDMI, ...)"
    echo "  [source]: select default audio input (microphone, ...)"
}

case $1 in
    sink)
        STREAMS=sink-inputs; MOVE=move-sink-input
        TITLE="Audio output"; ICON="$HOME/.config/i3/share/64x64/volume_icon.png"
        ;;
    source)
        STREAMS=source-outputs; MOVE=move-source-output
        TITLE="Audio input"; ICON="$HOME/.config/i3/share/64x64/microphone.png"
        ;;
    *)
        show_help_message
        exit 1
esac
TYPE=$1

# One "name<TAB>description" line per device. Monitor sources (".monitor") record
# what a sink plays, not a microphone, so they are left out.
list_devices () {
    pactl list "${TYPE}s" | awk -F': ' '
        /^[[:space:]]*Name: /        { name = $2 }
        /^[[:space:]]*Description: / { if (name !~ /\.monitor$/) print name "\t" $2 }'
}

DEFAULT=$(pactl "get-default-$TYPE") || {
    notify-send -u normal -a "$TITLE" "$TITLE" "Cannot reach the sound server" --icon="$ICON"
    exit 1
}
readarray -t DEVICES < <(list_devices)
if (( ${#DEVICES[@]} == 0 )); then
    notify-send -u normal -a "$TITLE" "$TITLE" "No device found" --icon="$ICON"
    exit 1
fi

# Show descriptions, with the current default marked
INDEX=$(for device in "${DEVICES[@]}"; do
            [[ ${device%%$'\t'*} == "$DEFAULT" ]] && mark="● " || mark="  "
            printf '%s%s\n' "$mark" "${device#*$'\t'}"
        done | rofi -dmenu -i -no-custom -format i -config "$ROFI_CONFIG" -p "$TITLE") || exit 0
[[ -n $INDEX ]] || exit 0

NAME=${DEVICES[$INDEX]%%$'\t'*}
DESCRIPTION=${DEVICES[$INDEX]#*$'\t'}

pactl "set-default-$TYPE" "$NAME" || {
    notify-send -u normal -a "$TITLE" "$TITLE" "Failed to switch to $DESCRIPTION" --icon="$ICON"
    exit 1
}
# Move the running streams (first column of the short list is the stream id)
pactl list short "$STREAMS" | while read -r id _; do
    pactl "$MOVE" "$id" "$NAME" 2>/dev/null
done

notify-send -u low -a "$TITLE" "$TITLE" "$DESCRIPTION" --icon="$ICON"
