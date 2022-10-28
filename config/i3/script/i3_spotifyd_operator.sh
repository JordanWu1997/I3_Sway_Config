#!/usr/bin/env bash

ICON="$HOME/.config/spotifyd/spotify.png"

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
        killall spotifyd; spotifyd
        notify-send "Spotifyd" "Spotifyd is reloaded" --icon=${ICON}
        ;;
    *)
        echo enable, disalbe, reload
esac
