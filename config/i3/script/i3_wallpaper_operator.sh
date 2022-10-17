#!/usr/bin/env bash

# Wallpaper
DEFAULT_WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
DEFAULT_I3_WALLPAPER="$HOME/.config/i3/share/default_i3_wallpaper.png"
VARIETY_INFO="$HOME/.config/variety/wallpaper/wallpaper.jpg.txt"
VARIETY_WALLPAPER="$(cat $VARIETY_INFO)"
FEH_WALLPAPER=$(awk -F\' 'NR==2 {print $2}' $HOME/.fehbg | xargs)

initialization () {
    # Create default wallpaper if there is none
    if [ ! -f "$DEFAULT_WALLPAPER" ]; then
        cp "$DEFAULT_I3_WALLPAPER" "$DEFAULT_WALLPAPER"
    fi
}

wallpaper_operation () {
    case $1 in
        "variety")
            case $2 in
                "set_default")
                    if [[ "$VARIETY_WALLPAPER" != "$DEFAULT_WALLPAPER" ]]; then
                        rm -f "$DEFAULT_WALLPAPER"
                        cp "$VARIETY_WALLPAPER" "$DEFAULT_WALLPAPER"
                    else
                        notify-send -u low "Wallpaper" "Already saved as default wallpaper"
                    fi
                    ;;
                "save_current")
                    cp "$VARIETY_WALLPAPER" "$WALLPAPERV"
                    ;;
            esac
            ;;
        "feh")
            case $2 in
                "set_default")
                    if [[  "$FEH_WALLPAPER" != "$DEFAULT_WALLPAPER" ]]; then
                        rm -f "$DEFAULT_WALLPAPER"
                        cp "$FEH_WALLPAPER" "$DEFAULT_WALLPAPER"
                    else
                        notify-send -u low "Wallpaper" "Already saved as default wallpaper"
                    fi
                    ;;
                "save_current")
                    cp "$FEH_WALLPAPER" "$WALLPAPERF"
                    ;;
            esac
            ;;
        *)
            echo $0
            ;;
    esac
}

# Main program
initialization
wallpaper_operation $1 $2
