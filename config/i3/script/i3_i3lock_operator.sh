#!/usr/bin/env bash

CURRENT="$HOME/.config/i3/share/default_wallpaper"
DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_i3lock_operator.sh [operation]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start i3lock with default wallpaper"
    echo "  [current]: start i3lock with current wallpaper"
}

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
                show_wrong_usage_message
                echo
                show_help_message
                exit
        esac
    fi
}

# Main
i3lock_operator $1
