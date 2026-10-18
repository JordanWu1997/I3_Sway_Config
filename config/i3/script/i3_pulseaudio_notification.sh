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
    echo "  [status]: print output and microphone state for the System view"
}

pulseaudio_notification () {
    case $1 in
        'status')
            local sink_volume source_volume sink_mute source_mute
            sink_volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null) || {
                printf 'Audio | unavailable\n'
                return 0
            }
            sink_volume=$(grep -o -m1 '[0-9][0-9]*%' <<< "$sink_volume" | head -n 1)
            sink_mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)
            source_volume=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null)
            source_volume=$(grep -o -m1 '[0-9][0-9]*%' <<< "$source_volume" | head -n 1)
            source_mute=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)
            case $sink_mute in
                *yes*) sink_mute=muted ;;
                *no*) sink_mute=unmuted ;;
                *) sink_mute=unknown ;;
            esac
            case $source_mute in
                *yes*) source_mute=muted ;;
                *no*) source_mute=unmuted ;;
                *) source_mute=unknown ;;
            esac
            printf 'Audio | output %s (%s) · microphone %s (%s)\n' \
                "${sink_volume:-unknown}" "$sink_mute" "${source_volume:-unknown}" "$source_mute"
            ;;
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
