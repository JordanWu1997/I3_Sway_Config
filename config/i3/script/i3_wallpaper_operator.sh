#!/usr/bin/env bash

# Wallpaper
DEFAULT_WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
DEFAULT_I3_WALLPAPER="$HOME/.config/i3/share/default_i3_wallpaper.png"
ICON="$HOME/.config/i3/share/64x64/picture.png"
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_wallpaper_operator.sh [tools] [operations] ([input_diretory])"
    echo
    echo "TOOLS"
    echo "  [variety]: variety"
    echo "  [feh]: feh"
    echo
    echo "OPERATIONS"
    echo "  [set_default]: save current wallpaper as default wallpaper"
    echo "  [save_curreent]: save current wallpaper to favorites"
    echo "  [show_current]: show current wallpaper name"
    echo "  [random]: randomly select wallpaper from input_diretory"
    echo "  [select]: select wallpaper from input_directory"
    echo
    echo "OPERATIONS (FEH-ONLY)"
    echo "  [restore_default]: restore to default wallpaper"
    echo
    echo "OPERATIONS (VARIETY-ONLY)"
    echo "  [previous]: previous variety wallpaper"
    echo "  [next]: next variety wallpaper"
    echo "  [pause]: pause variety routine wallpaper changing"
    echo "  [resume]: resume variety routine wallpaper changing"
    echo "  [quit]: quit variety"
    echo
}

initialization () {
    # Create default wallpaper if there is none
    if [ ! -f "$DEFAULT_WALLPAPER" ]; then
        cp "$DEFAULT_I3_WALLPAPER" "$DEFAULT_WALLPAPER"
    fi
}

feh_operation () {
    FEH_WALLPAPER=$(awk -F\' 'NR==2 {print $2}' $HOME/.fehbg | xargs)
    case $2 in
        "set_default")
            initialization
            if [[  "$FEH_WALLPAPER" != "$DEFAULT_WALLPAPER" ]]; then
                rm -f "$DEFAULT_WALLPAPER"
                cp "$FEH_WALLPAPER" "$DEFAULT_WALLPAPER"
                notify-send -u low "Wallpaper Mode" "Save current as default" --icon=${ICON}
            else
                notify-send -u low "Wallpaper Mode" "Already saved as default wallpaper" --icon=${ICON}
            fi
            ;;
        "save_current")
            cp "$FEH_WALLPAPER" "$WALLPAPERF"
            notify-send -u low "Wallpaper Mode" "Save current to favorite" --icon=${ICON}
            ;;
        "show_current")
            notify-send -u low "Wallpaper Mode" "Current feh: $(echo "$FEH_WALLPAPER" | rev | cut -d\/ -f1 | rev)" --icon=${ICON}
            ;;
        "random")
            WALLPAPER=$(find "$3" -name '*.*g' | shuf -n1)
            feh --bg-fill "$WALLPAPER"
            notify-send -u low "Wallpaper Mode" "Random from $(basename $3)\n$WALLPAPER" --icon=${ICON}
            ;;
        "select")
            WALLPAPER=$(find "$3" -name '*.*g' | rofi -config "$ROFI_SELECTOR_CONFIG" -dmenu -i -p "$(basename $3)")
            if [[ -z "$WALLPAPER" ]]; then
                return
            fi
            feh --bg-fill "$WALLPAPER"
            notify-send -u low "Wallpaper Mode" "Select from $(basename $3)\n$WALLPAPER" --icon=${ICON}
            ;;
        # Feh-ONLY
        "restore_default")
            feh --bg-fill "$DEFAULT_WALLPAPER"
            notify-send -u low "Wallpaper Mode" "Restore wallpaper to default" --icon=${ICON}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

variety_operation () {
    VARIETY_INFO="$HOME/.config/variety/wallpaper/wallpaper.jpg.txt"
    VARIETY_WALLPAPER="$(cat $VARIETY_INFO)"
    case $2 in
        "set_default")
            initialization
            if [[ "$VARIETY_WALLPAPER" != "$DEFAULT_WALLPAPER" ]]; then
                rm -f "$DEFAULT_WALLPAPER"
                cp "$VARIETY_WALLPAPER" "$DEFAULT_WALLPAPER"
                notify-send -u low "Variety Mode" "Save current as default wallpaper (VARIETY)" --icon=${ICON}
            else
                notify-send -u low "Variety Mode" "Already saved as default wallpaper" --icon=${ICON}
            fi
            ;;
        "save_current")
            variety --favorite
            notify-send -u low "Variety Mode" "Save to Favorite (VARIETY)" --icon=${ICON}
            ;;
        "show_current")
            notify-send -u low "Variety Mode" "Current variety: $(echo "$VARIETY_WALLPAPER" | rev | cut -d\/ -f1 | rev)" --icon=${ICON}
            ;;
        "random")
            WALLPAPER=$(find "$3" -name '*.*g' | shuf -n1)
            variety --set="$WALLPAPER"
            notify-send -u low "Variety Mode" "Random from $(basename $3)\n$WALLPAPER" --icon=${ICON}
            ;;
        "select")
            WALLPAPER=$(find "$3" -name '*.*g' | rofi -config "$ROFI_SELECTOR_CONFIG" -dmenu -i -p "$(basename $3)")
            variety --set="$WALLPAPER"
            notify-send -u low "Variety Mode" "Select from $(basename $3)\n$WALLPAPER" --icon=${ICON}
            ;;
        # Variety-ONLY
        "previous")
            variety --previous
            notify-send -u low "Variety Mode" "Previous Wallpaper (VARIETY)" --icon=${ICON}
            ;;
        "next")
            variety --next
            notify-send -u low "Variety Mode" "Next Wallpaper (VARIETY)" --icon=${ICON}
            ;;
        "pause")
            variety --pause
            notify-send -u low "Variety Mode" "Pause Changing Wallpaper (VARIETY)" --icon=${ICON}
            ;;
        "resume")
            variety --resume
            notify-send -u low "Variety Mode" "Resume Changing Wallpaper (VARIETY)" --icon=${ICON}
            ;;
        "quit")
            variety --quit
            notify-send -u low "Variety Mode" "Quit Variety" --icon=${ICON}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

main () {
    case $1 in
        "feh")
            feh_operation $@
            ;;
        "variety")
            variety_operation $@
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main program
main $@
