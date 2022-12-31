#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_MPRIS_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [play-pause]: play-pause"
    echo "  [stop]: stop"
    echo "  [next]: next one"
    echo "  [prev]: previous one"
    echo "  [fast-forward]: fast-forward"
    echo "  [rewind]: rewind"
}

# Select player
select_MPRIS_player () {
    PLAYER=$(playerctl --list-all | rofi -dmenu -auto-select -p 'MPRIS player')
    if [[ -z ${PLAYER} ]]; then
        exit
    fi
}

# Operation
MPRIS_operation () {
    # Select player
    select_MPRIS_player
    # Operation
    case $1 in
        'play-pause')
            playerctl play-pause -p ${PLAYER}
            ;;
        'stop')
            playerctl stop -p ${PLAYER}
            ;;
        'next')
            playerctl next -p ${PLAYER}
            ;;
        'prev')
            playerctl previous -p ${PLAYER}
            ;;
        'fast-forward')
            TIME=$(rofi -dmenu -p 'Fast-forward (sec)')
            if [[ ${PLAYER} == *'spotifyd'* ]]; then
                spt playback --device spotifyd --seek +${TIME}
            else
                playerctl position ${TIME}+ -p ${PLAYER}
            fi
            ;;
        'rewind')
            TIME=$(rofi -dmenu -p 'Rewind (sec)')
            if [[ ${PLAYER} == *'spotifyd'* ]]; then
                spt playback --device spotifyd --seek -${TIME}
            else
                playerctl position ${TIME}- -p ${PLAYER}
            fi
            ;;
        *)
            show_wrong_message
            echo
            show_help_message
            exit
    esac
    # Notification
    $I3_SCRIPT/i3_MPRIS_notification.sh playing
}

# Main
MPRIS_operation $1
