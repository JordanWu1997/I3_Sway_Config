#!/usr/bin/env bash

ICON="$HOME/.config/spotifyd/spotify.png"

help_message () {
    echo "Usage":
    echo "  i3_spotifyd_operator.sh [operation]"
    echo ""
    echo "OPERATIONS"
    echo "  [status]: current spotifyd status"
    echo "  [enable]: enable spotifyd"
    echo "  [disable]: disable spotifyd"
    echo "  [reload]: reload spotifyd"
    echo "  [reload_all]: reload spotifyd and reload spt"
}

case $1 in
    "status")
        if [ ! -z $(pgrep -f ^spotifyd) ]; then
            notify-send "Spotifyd" "Spotifyd is active" --icon=${ICON}
        else
            notify-send "Spotifyd" "Spotifyd is not active" --icon=${ICON}
        fi
        ;;
    "enable")
        spotifyd
        notify-send "Spotifyd" "Spotifyd is enabled" --icon=${ICON}
        ;;
    "disable")
        killall spotifyd
        notify-send "Spotifyd" "Spotifyd is disabled" --icon=${ICON}
        ;;
    "reload")
        killall spotifyd
        spotifyd
        notify-send "Spotifyd" "Spotifyd is reloaded" --icon=${ICON}
        ;;
    "reload_all")
        killall spotifyd
        spotifyd
        sleep 1.5
        spt playback --transfer spotifyd
        notify-send "Spotifyd" "Spotifyd is reloaded" --icon=${ICON}
        ;;
    *)
        help_message
esac
