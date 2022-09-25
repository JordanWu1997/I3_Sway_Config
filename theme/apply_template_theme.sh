#!/usr/bin/env bash

replace_wal_color_file () {
    command cp $1 $HOME/.cache/wal/
}

if [ ! -z $1 ]; then
    echo Input: $1
    # Check input template
    THEMES=$(command ls -D ./templates/)
    if [[ ! ${THEMES[*]} =~ $1 ]]; then
        echo Available Templates:
        for THEME in ${THEMES[@]}; do
            echo $THEME
        done
        exit
    else
        # Replace Files
        replace_wal_color_file "./templates/$1/colors"
        replace_wal_color_file "./templates/$1/colors.Xresources"
        replace_wal_color_file "./templates/$1/colors.sh"
        replace_wal_color_file "./templates/$1/colors.json"
        replace_wal_color_file "./templates/$1/colors-kitty.conf"
        replace_wal_color_file "./templates/$1/colors-rofi-dark.rasi"
        # Reload Xresources
        xrdb -load ~/.Xresources
        # Reload i3
        i3-msg reload
    fi
fi
