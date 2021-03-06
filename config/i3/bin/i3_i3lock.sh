#!/bin/bash

current="$HOME/.config/i3/share/default_wallpaper"
default="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"

if ( file $current | grep -q PNG ); then
    if [ -f $current.png ]; then
        rm -f $current.png
    fi
    i3lock -t -f -i $current
else
    if [ $1 == "default" ]; then
        i3lock -t -f -i $default
    elif [ $1 == "current" ]; then
        if [ ! -f $current.png ]; then
            mogrify -resize 1920x1080 -format png $current
        fi
        i3lock -t -f -i $current.png
    else
        i3lock -t -f -i $default
    fi
fi
