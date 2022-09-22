#!/usr/bin/env bash

case $1 in
    "playing")
        PLAYING=$(playerctl metadata --format "Title: {{ title }}\nArtist: {{ artist }}\nAlbum: {{ album }}")
        notify-send -u low "MPRIS: Playing" "$PLAYING"
        ;;
    "playing_all")
        PLAYING=$(playerctl metadata -a --format "Title: {{ title }}\nArtist: {{ artist }}\nAlbum: {{ album }}\n")
        notify-send -u low "MPRIS: All Playing" "$PLAYING"
        ;;
    "player_all")
        notify-send -u low "MPRIS: Active Players" "$(playerctl --list-all)"
        ;;
    *)
        echo "playing", "playing_all", "player_all"
esac
