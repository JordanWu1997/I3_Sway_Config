#!/usr/bin/env bash

current="$HOME/.config/i3/share/default_wallpaper"
default="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"

if ( file $current | grep -q PNG ); then
    [ -f $current.png ] && rm -f $current.png
    i3lock -t -f -i $current
else
    case $1 in
        "default")
            i3lock -t -f -i $default
            ;;
        "current")
            [ ! -f $current.png ] && mogrify -resize 1920x1080 -format png $current
            i3lock -t -f -i $current.png
            ;;
        *)
            i3lock -t -f -i $default
    esac
fi
