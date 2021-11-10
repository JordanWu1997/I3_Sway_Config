#!/usr/bin/env bash

if [ -z $1 ]; then
    echo $0
elif [ $1 == "set_default" ]; then
    if [ $2 == "feh" ]; then
        if [ ! -f $HOME/.config/i3/share/default_wallpaper ]; then
            /bin/cp $HOME/.config/i3/share/default_i3_wallpaper.png $HOME/.config/i3/share/default_wallpaper
        else
            rm -f $home/.config/i3/share/default_wallpaper
            /bin/cp $(awk 'NR==2 {print $4}' $HOME/.fehbg | xargs) $HOME/.config/i3/share/default_wallpaper
        fi
    elif [ $2 == "variety"]; then
        if [ ! -f $HOME/.config/i3/share/default_wallpaper ]; then
            /bin/cp $HOME/.config/i3/share/default_i3_wallpaper.png $HOME/.config/i3/share/default_wallpaper
        else
            rm -f $home/.config/i3/share/default_wallpaper
            /bin/cp $(cat $HOME/.config/variety/wallpaper/wallpaper.jpg.txt) $HOME/.config/i3/share/default_wallpaper
        fi
    else
        echo $0
    fi
elif [ $1 == "save_current" ]; then
    current=$(awk 'NR==2 {print $4}' $HOME/.fehbg | xargs)
    default=$HOME/.config/i3/share/default_wallpaper

    if [ "$current" != "$default" ]; then
        /bin/cp $current $wallpaperf
    fi
else
    echo $0
fi
