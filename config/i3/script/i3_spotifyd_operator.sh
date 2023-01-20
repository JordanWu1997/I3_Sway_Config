#!/usr/bin/env bash

ICON="$HOME/.config/spotifyd/spotify.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_spotifyd_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [playing]: show current playing"
    echo "  [status]: show current spotifyd status"
    echo "  [enable]: enable spotifyd"
    echo "  [disable]: disable spotifyd"
    echo "  [reload]: reload spotifyd"
    echo "  [attach]: attach spotifyd to spt"
    echo "  [reload_and_attach]: reload spotifyd and attach it to spt"
}

case $1 in
    "status")
        if [ ! -z $(pgrep -f ^spotifyd) ]; then
            notify-send "Spotifyd" "Spotifyd is active" --icon=${ICON}
        else
            notify-send "Spotifyd" "Spotifyd is not active" --icon=${ICON}
        fi
        ;;
    "playing")
        $HOME/.config/spotifyd/song_notification.sh
        ;;
    "enable")
        spotifyd
        notify-send "Spotifyd" "Spotifyd is enabled" --icon=${ICON}
        ;;
    "disable")
        killall spotifyd
        notify-send "Spotifyd" "Spotifyd is disabled" --icon=${ICON}
        ;;
    "attach")
        spt playback --transfer spotifyd
        notify-send "Spotifyd" "Spotifyd is attatched to spt" --icon=${ICON}
        ;;
    "reload")
        killall spotifyd
        spotifyd
        notify-send "Spotifyd" "Spotifyd is reloaded" --icon=${ICON}
        ;;
    "reload_and_attach")
        killall spotifyd
        spotifyd
        sleep 1.5
        spt playback --transfer spotifyd
        notify-send "Spotifyd" "Spotifyd is reloaded and attached to spt" --icon=${ICON}
        ;;
    *)
        show_wrong_usage_message
        echo
        show_help_message
        exit
esac
