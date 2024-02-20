#!/usr/bin/env bash

# Wallpaper
DEFAULT_WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
DEFAULT_I3_WALLPAPER="$HOME/.config/i3/share/default_i3_wallpaper.png"
VARIETY_INFO="$HOME/.config/variety/wallpaper/wallpaper.jpg.txt"
VARIETY_WALLPAPER="$(cat $VARIETY_INFO)"
FEH_WALLPAPER=$(awk -F\' 'NR==2 {print $2}' $HOME/.fehbg | xargs)
ICON="/home/jordankhwu/.config/i3/share/picture.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_wallpaper_operator.sh [tools] [operations]"
    echo
    echo "TOOLS"
    echo "  [variety]: variety"
    echo "  [feh]: feh"
    echo
    echo "OPERATIONS"
    echo "  [set_default]: save current wallpaper as default wallpaper"
    echo "  [save_curreent]: save current wallpaper to favorites"
    echo "  [show_current]: show current wallpaper name"
}

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
                    initialization
                    if [[ "$VARIETY_WALLPAPER" != "$DEFAULT_WALLPAPER" ]]; then
                        rm -f "$DEFAULT_WALLPAPER"
                        cp "$VARIETY_WALLPAPER" "$DEFAULT_WALLPAPER"
                    else
                        notify-send -u low "Variety Mode" "Already saved as default wallpaper" --icon=${ICON}
                    fi
                    ;;
                "save_current")
                    cp "$VARIETY_WALLPAPER" "$WALLPAPERV"
                    ;;
                "show_current")
                    notify-send -u low "Variety Mode" "Current variety: $(echo $VARIETY_WALLPAPER | rev | cut -d\/ -f1 | rev)" --icon=${ICON}
                    ;;
                *)
                    show_wrong_usage_message
                    echo
                    show_help_message
                    exit
            esac
            ;;
        "feh")
            case $2 in
                "set_default")
                    initialization
                    if [[  "$FEH_WALLPAPER" != "$DEFAULT_WALLPAPER" ]]; then
                        rm -f "$DEFAULT_WALLPAPER"
                        cp "$FEH_WALLPAPER" "$DEFAULT_WALLPAPER"
                    else
                        notify-send -u low "Wallpaper" "Already saved as default wallpaper" --icon=${ICON}
                    fi
                    ;;
                "save_current")
                    cp "$FEH_WALLPAPER" "$WALLPAPERF"
                    ;;
                "show_current")
                    notify-send -u low "Wallpaper Mode" "Current feh: $(echo $FEH_WALLPAPER | rev | cut -d\/ -f1 | rev)" --icon=${ICON}
                    ;;
                *)
                    show_wrong_usage_message
                    echo
                    show_help_message
                    exit
            esac
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main program
wallpaper_operation $1 $2
