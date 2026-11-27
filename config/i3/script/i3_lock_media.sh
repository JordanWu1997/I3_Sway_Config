#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Pause playing media when the screen locks, tell what was paused on unlock
###########################################################

# Requirements:
#   playerctl, notify-send

# Usage: i3_lock_media.sh [pause|notify TEXT]
#   pause: pause every MPRIS player that is playing and print one
#       "Artist - Title (player)" line per paused player (nothing if none played).
#   notify TEXT: show TEXT (the pause output) as a "Paused while locked" notification;
#       does nothing when TEXT is empty.
# Called by i3_i3lock_operator.sh and sway_lock_operator.sh: pause before the lock,
# notify after unlock. Nothing is resumed automatically, so audio never starts
# playing by itself (e.g. on unlock in a meeting room).

ICON="$HOME/.config/i3/share/64x64/video_player.png"

pause_playing () {
    local player
    command -v playerctl > /dev/null || return 0
    for player in $(playerctl --list-all 2> /dev/null); do
        [[ $(playerctl -p "$player" status 2> /dev/null) == Playing ]] || continue
        playerctl -p "$player" metadata --format "{{ artist }} - {{ title }} (${player%%.*})" 2> /dev/null \
            | sed 's/^ - //'
        playerctl -p "$player" pause
    done
}

case $1 in
    pause)
        pause_playing
        ;;
    notify)
        if [[ -n $2 ]]; then
            notify-send -u low -a "Screen lock" "Paused while locked" "$2" --icon="$ICON"
        fi
        ;;
    *)
        echo "Usage: i3_lock_media.sh [pause|notify TEXT]"
        exit 1
esac
