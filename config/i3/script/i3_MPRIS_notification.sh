#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_MPRIS_notification.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [playing]: show playing"
    echo "  [playing_all]: show all playing"
    echo "  [player_all]: show all players"
}

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
        show_wrong_usage_message
        echo
        show_help_message
        exit
esac
