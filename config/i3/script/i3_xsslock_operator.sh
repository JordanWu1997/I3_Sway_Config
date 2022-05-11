#!/usr/bin/env bash

DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"
CURRENT_DEFAULT="$HOME/.config/i3/share/default_wallpaper"
CURRENT=$(head -n 2 "$HOME/.fehbg" | tail -n 1 | cut -d"'" -f2)
IMAGESIZE="1920x1080"

killall xss-lock

[ -f $CURRENT_DEFAULT.png ] && rm -f $CURRENT_DEFAULT.png
case $1 in
    "current_default")
        mogrify -resize $IMAGESIZE -format png $CURRENT_DEFAULT
        sleep 1
        i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3lock -nfti $CURRENT_DEFAULT.png"
        ;;
    "current")
        mogrify -resize $IMAGESIZE -format png $CURRENT
        CURRENT_PNG="$(dirname $CURRENT)/$(basename $CURRENT | cut -d'.' -f1).png"
        sleep 1
        i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3lock -nfti $CURRENT_PNG"
        ;;
    *)
        i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3lock -nfti $DEFAULT"
        ;;
esac
