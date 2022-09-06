#!/usr/bin/env bash

CURRENT="$HOME/.config/i3/share/default_wallpaper"
DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"

i3lock_operator () {
    if ( file $CURRENT | grep -q PNG ); then
        [ -f $CURRENT.png ] && rm -f $CURRENT.png
        i3lock -t -f -i $CURRENT
    else
        case $1 in
            "default")
                i3lock -t -f -i $DEFAULT
                ;;
            "current")
                [ ! -f $CURRENT.png ] && mogrify -resize 1920x1080 -format png $CURRENT
                i3lock -t -f -i $CURRENT.png
                ;;
            *)
                i3lock -t -f -i $DEFAULT
                ;;
        esac
    fi
}

# Main
i3lock_operator $1
