#!/usr/bin/env bash

# Wallpaper
DEFAULT_WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
DEFAULT_I3_WALLPAPER="$HOME/.config/i3/share/default_i3_wallpaper.png"
VARIETY_INFO="$HOME/.config/variety/wallpaper/wallpaper.jpg.txt"
VARIETY_WALLPAPER="$(cat $VARIETY_INFO)"
FEH_WALLPAPER=$(awk 'NR==2 {print $4}' $HOME/.fehbg | xargs)

# Create default wallpaper if there is none
if [ ! -f $DEFAULT_WALLPAPER ]; then
    cp $DEFAULT_I3_WALLPAPER $DEFAULT_WALLPAPER
fi

# Main program
case $1 in
    "variety")
        case $2 in
            "set_default")
                rm -f $DEFAULT_WALLPAPER
                cp $VARIETY_WALLPAPER $DEFAULT_WALLPAPER
                ;;
            "save_current")
                cp $VARIETY_WALLPAPER $WALLPAPERV
                ;;
        esac
        ;;
    "feh")
        case $2 in
            "set_default")
                rm -f $DEFAULT_WALLPAPER
                cp $FEH_WALLPAPER $DEFAULT_WALLPAPER
                ;;
            "save_current")
                cp $FEH_WALLPAPER $WALLPAPERF
                ;;
        esac
        ;;
    *)
        echo $0
        ;;
esac
