#!/bin/bash

current="$HOME/.config/i3/share/default_wallpaper"
default="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"

killall xss-lock

if ( file $current | grep -q PNG ); then
    if [ -f $current.png ]; then
        rm -f $current.png
    fi
    xss-lock -v --transfer-sleep-lock -- i3lock -t -f -i $current
else
    if [ $1 == "default" ]; then
        xss-lock -v --transfer-sleep-lock -- i3lock -t -f -i $default
    elif [ $1 == "current" ]; then
        if [ ! -f $current.png ]; then
            mogrify -format png $current
        fi
        xss-lock -v --transfer-sleep-lock -- i3lock -t -f -i $current.png
    else
        xss-lock -v --transfer-sleep-lock -- i3lock -t -f -i $default
    fi
fi
