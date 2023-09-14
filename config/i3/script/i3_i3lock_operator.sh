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
    echo "  i3_i3lock_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start i3lock with default wallpaper"
    echo "  [current_default]: start i3lock with current default wallpaper"
    echo "  [current]: start i3lock iwth current wallpaper"
}

i3lock_operator () {
    case $1 in
        "default")
            i3lock -n -t -f -i ${DEFAULT}
            ;;
        "current_default")
            # If there is no current default, copy default from an existing default wallpaper
            [ ! -f ${CURRENT_DEFAULT} ] && cp ${DEFAULT} ${CURRENT_DEFAULT}
            # If current default file extension does not end with png, convert it to a png file
            [ ! -f ${CURRENT_DEFAULT}.png ] && mogrify -resize ${IMAGESIZE} -format png ${CURRENT_DEFAULT}
            i3lock -n -t -f -i ${CURRENT_DEFAULT}
            ;;
        "current")
            if ( file ${CURRENT} | grep -q PNG ); then
                CURRENT_PNG=${CURRENT}
            elif [[ -f ${CURRENT}.png ]]; then
                CURRENT_PNG=${CURRENT}.png
            # If current file is not a png file, convert it a to png file
            else
                mogrify -resize ${IMAGESIZE} -format png ${CURRENT}
                CURRENT_PNG="$(dirname ${CURRENT})/$(basename ${CURRENT} | cut -d'.' -f1).png"
            fi
            i3lock -n -t -f -i ${CURRENT_PNG}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
#pkill -u "${USER}" -USR1 dunst
dunstctl set-paused true
i3lock_operator $1
#pkill -u "${USER}" -USR2 dunst
dunstctl set-paused false
