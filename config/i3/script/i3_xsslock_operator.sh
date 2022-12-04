#!/usr/bin/env bash

DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"
CURRENT_DEFAULT="$HOME/.config/i3/share/default_wallpaper"
CURRENT=$(head -n 2 "$HOME/.fehbg" | tail -n 1 | cut -d"'" -f2)
IMAGESIZE="1920x1080"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_xsslock_operator.sh [operation]"
    echo ""
    echo "OPERATIONS"
    echo "  [current_default]: start xsslock with current default wallpaper"
    echo "  [current]: start xsslock with current wallpaper"
}

initialization () {
    killall xss-lock
    [ -f $CURRENT_DEFAULT.png ] && rm -f $CURRENT_DEFAULT.png
}

xsslock_operation () {
    case $1 in
        "current_default")
            initialization
            mogrify -resize $IMAGESIZE -format png $CURRENT_DEFAULT
            sleep 1
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3lock -nfti $CURRENT_DEFAULT.png"
            ;;
        "current")
            initialization
            mogrify -resize $IMAGESIZE -format png $CURRENT
            CURRENT_PNG="$(dirname $CURRENT)/$(basename $CURRENT | cut -d'.' -f1).png"
            sleep 1
            i3-msg exec "xss-lock -v --transfer-sleep-lock -- i3lock -nfti $CURRENT_PNG"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
xsslock_operation $1
