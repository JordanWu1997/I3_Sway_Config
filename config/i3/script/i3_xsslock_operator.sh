#!/usr/bin/env bash

CURRENT="$HOME/.config/i3/share/default_wallpaper"
DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"

killall xss-lock

if ( file $CURRENT | grep -q PNG ); then
    [ -f $CURRENT.png ] && rm -f $CURRENT.png
    # Note: i3lock -n flag is needed for unlock functionality
    xss-lock -v --transfer-sleep-lock -- i3lock -nfti $CURRENT
else
    case $1 in
        "default")
            xss-lock -v --transfer-sleep-lock -- i3lock -nfti $DEFAULT
            ;;
        "current")
            mogrify -resize 1920x1080 -format png $CURRENT
            sleep 1
            xss-lock -v --transfer-sleep-lock -- i3lock -nfti $CURRENT.png
            ;;
        *)
            xss-lock -v --transfer-sleep-lock -- i3lock -nfti $DEFAULT
    esac
fi
