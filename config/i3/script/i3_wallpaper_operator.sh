#!/usr/bin/env bash

# Wallpaper
default_wallpaper="$HOME/.config/i3/share/default_wallpaper"
default_i3_wallpaper="$HOME/.config/i3/share/default_i3_wallpaper.png"
variety_info="$HOME/.config/variety/wallpaper/wallpaper.jpg.txt"
variety_wallpaper="$(cat $variety_info)"
feh_wallpaper=$(awk 'NR==2 {print $4}' $HOME/.fehbg | xargs)

# Create default wallpaper if there is none
if [ ! -f $default_wallpaper ]; then
    cp $default_i3_wallpaper $default_wallpaper
fi

# Main program
if [ -z $1 ]; then
    echo $0
elif [ $1 == "variety" ]; then
    if [ -z $2 ]; then
        echo $0
    elif [ $2 == "set_default" ]; then
        rm -f $default_wallpaper; cp $variety_wallpaper $default_wallpaper
    elif [ $2 == "save_current" ]; then
        cp $variety_wallpaper $WALLPAPERV
    else
        $0
    fi
elif [ $1 == "feh" ]; then
    if [ -z $2 ]; then
        echo $0
    elif [ $2 == "set_default" ]; then
        rm -f $default_wallpaper; cp $feh_wallpaper $default_wallpaper
    elif [ $2 == "save_current" ]; then
        cp $feh_wallpaper $WALLPAPERF
    else
        $0
    fi
else
    echo $0
fi
