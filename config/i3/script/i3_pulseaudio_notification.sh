#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_pulseaudio_notification.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [sink]: show sink (speaker) status"
    echo "  [source]: show source (microphone) status"
}

pulseaudio_notification () {
    case $1 in
        'sink'|'')
            # Pulseaudio volumes from pulsemixer
            VOLUMES=$(pulsemixer --get-volume)
            L_VOLUME=$(echo ${VOLUMES} | awk '{print $1}')
            R_VOLUME=$(echo ${VOLUMES} | awk '{print $2}')
            # Mute label
            if [ $(pulsemixer --get-mute) == 0 ]; then
                ICON="$HOME/.config/i3/share/64x64/volume_icon.png"
                CONTEXT="L:${L_VOLUME}% R:${R_VOLUME}%"
            else
                ICON="$HOME/.config/i3/share/64x64/mute_icon.png"
                CONTEXT="MUTED (L:${L_VOLUME}% R:${R_VOLUME}%)"
            fi
            # Send notification
            NOTIFY_SEND_VERSION=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
            if (( $(echo ${NOTIFY_SEND_VERSION}) > 7 | bc -l )); then
                NOTIFY_ID=99709201
                notify-send -r ${NOTIFY_ID} -u low -a "Volume" "${CONTEXT}" --icon="${ICON}"
            else
                notify-send -u low -a "Volume" "${CONTEXT}" --icon="${ICON}"
            fi
            ;;
        'source')
            # Pulseaudio volumes from pactl
            VOLUMES=$(pactl get-source-volume @DEFAULT_SOURCE@ | cut -d: -f2-)
            L_VOLUME=$(echo ${VOLUMES} | cut -d, -f1 | cut -d/ -f2 | grep % | awk '{print $1}')
            R_VOLUME=$(echo ${VOLUMES} | cut -d, -f2 | cut -d/ -f2 | grep % | awk '{print $1}')
            # Mute label
            if [ $(pactl get-source-mute @DEFAULT_SOURCE@ | cut -d: -f2) == 'no' ]; then
                ICON="$HOME/.config/i3/share/64x64/microphone.png"
                CONTEXT="L:${L_VOLUME} R:${R_VOLUME}"
            else
                ICON="$HOME/.config/i3/share/64x64/microphone_mute.png"
                CONTEXT="MUTED (L:${L_VOLUME} R:${R_VOLUME})"
            fi
            # Send notification
            NOTIFY_SEND_VERSION=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
            if (( $(echo ${NOTIFY_SEND_VERSION}) > 7 | bc -l )); then
                NOTIFY_ID=99709201
                notify-send -r ${NOTIFY_ID} -u low -a "Volume" "${CONTEXT}" --icon="${ICON}"
            else
                notify-send -u low -a "Volume" "${CONTEXT}" --icon="${ICON}"
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
pulseaudio_notification $1
