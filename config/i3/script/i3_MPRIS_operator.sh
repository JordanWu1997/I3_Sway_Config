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
    PLAYER=$(playerctl --list-all | rofi -dmenu -auto-select -p "$1 [MPRIS player]")
    if [[ -z ${PLAYER} ]]; then
        exit
    fi
}

# Operation
MPRIS_operation () {
    # Operation
    case $1 in
        'play-pause')
            select_MPRIS_player play-pause
            playerctl play-pause -p ${PLAYER}
            ;;
        'stop')
            select_MPRIS_player stop
            playerctl stop -p ${PLAYER}
            ;;
        'next')
            select_MPRIS_player next
            playerctl next -p ${PLAYER}
            ;;
        'prev')
            select_MPRIS_player prev
            playerctl previous -p ${PLAYER}
            ;;
        'fast-forward')
            select_MPRIS_player fast-forward
            TIME=$(rofi -dmenu -p 'Fast-forward (sec)')
            if [[ -z ${TIME} ]]; then
                return
            fi
            if [[ ${PLAYER} == *'spotifyd'* ]]; then
                spt playback --device spotifyd --seek +${TIME}
            else
                playerctl position ${TIME}+ -p ${PLAYER}
            fi
            ;;
        'rewind')
            select_MPRIS_player rewind
            TIME=$(rofi -dmenu -p 'Rewind (sec)')
            if [[ -z ${TIME} ]]; then
                return
            fi
            if [[ ${PLAYER} == *'spotifyd'* ]]; then
                spt playback --device spotifyd --seek -${TIME}
            else
                playerctl position ${TIME}- -p ${PLAYER}
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    # Notification
    $I3_SCRIPT/i3_MPRIS_notification.sh playing
}

# Main
MPRIS_operation $1
