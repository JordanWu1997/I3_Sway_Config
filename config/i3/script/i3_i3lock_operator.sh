#!/usr/bin/env bash

DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"
CURRENT_DEFAULT="$HOME/.config/i3/share/default_wallpaper"
CURRENT=$(head -n 2 "$HOME/.fehbg" | tail -n 1 | cut -d"'" -f2)
IMAGESIZE="1920x1080"
BLUR="0x12"

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
    echo "  [current_default_wallpaper]: start i3lock with current default wallpaper"
    echo "  [current_wallpaper]: start i3lock with current wallpaper"
    echo "  [current_desktop]: start i3lock with current desktop screenshot"
}

i3lock_operator () {
    case $1 in
        "default")
            i3lock -n -t -f -i ${DEFAULT}
            ;;
        "current_default_wallpaper")
            # If there is no current default, copy default from an existing default wallpaper
            [ ! -f ${CURRENT_DEFAULT} ] && cp ${DEFAULT} ${CURRENT_DEFAULT}
            # If current default file extension does not end with png, convert it to a png file
            [ ! -f ${CURRENT_DEFAULT}.png ] && mogrify -resize ${IMAGESIZE} -format png ${CURRENT_DEFAULT}
            i3lock -n -t -f -i ${CURRENT_DEFAULT}
            ;;
        "current_wallpaper")
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
        "current_desktop")
            DESKTOP_IMAGE="/tmp/i3lock_screen.png"
            #flameshot full --path ${DESKTOP_IMAGE} &> /dev/null
            gnome-screenshot --file=${DESKTOP_IMAGE} &> /dev/null
            convert ${DESKTOP_IMAGE} -blur ${BLUR} ${DESKTOP_IMAGE}
            i3lock -n -t -f -i ${DESKTOP_IMAGE} && rm ${DESKTOP_IMAGE}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
if [[ $(dunstctl is-paused) == 'false' ]]; then
    #pkill -u "${USER}" -USR1 dunst
    dunstctl set-paused true

    # Locker
    i3lock_operator $1

    #pkill -u "${USER}" -USR2 dunst
    dunstctl set-paused false
else
    i3lock_operator $1
fi
