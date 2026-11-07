#!/usr/bin/env bash
# Ported from i3_wallpaper_operator.sh for sway.
# Replaced X11 tools:
#   - feh --bg-fill <file>     -> swaymsg output '*' bg <file> fill (sway spawns swaybg)
#   - ~/.fehbg (current file)  -> state file $SWAY_WALLPAPER_STATE (default ~/.cache/sway_wallpaper),
#                                 since swaybg cannot be queried
#   - variety                  -> unchanged (variety's set_wallpaper script supports sway/swaybg)
# The first argument (backend: feh|variety) is kept; "feh" now means "sway output bg".
# Subcommands and arguments are identical to the i3 version, plus:
#   feh restore_last : re-apply the wallpaper from the state file (default wallpaper if none)

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

# Wallpaper
DEFAULT_WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
DEFAULT_I3_WALLPAPER="$HOME/.config/i3/share/default_i3_wallpaper.png"
ICON="$HOME/.config/i3/share/64x64/picture.png"
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
SWAY_WALLPAPER_STATE="${SWAY_WALLPAPER_STATE:-$HOME/.cache/sway_wallpaper}"
# Background mode of "swaymsg output * bg" (feh --bg-fill equivalent)
SWAY_WALLPAPER_MODE="${SWAY_WALLPAPER_MODE:-fill}"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_wallpaper_operator.sh [tools] [operations] ([input_diretory])"
    echo
    echo "TOOLS"
    echo "  [variety]: variety"
    echo "  [feh]: sway output bg (swaybg); name kept from the i3 version"
    echo
    echo "OPERATIONS"
    echo "  [set_default]: save current wallpaper as default wallpaper"
    echo "  [save_current]: save current wallpaper to favorites (\$WALLPAPERF)"
    echo "  [show_current]: show current wallpaper name"
    echo "  [random]: randomly select wallpaper from input_diretory"
    echo "  [select]: select wallpaper from input_directory"
    echo
    echo "OPERATIONS (FEH-ONLY)"
    echo "  [restore_default] ([quiet]): restore to default wallpaper"
    echo "  [restore_last]: re-apply the last wallpaper set by this script"
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

# Set the wallpaper on every output and remember it (replacement of feh --bg-fill + ~/.fehbg)
sway_set_wallpaper () {
    local wallpaper=$1 escaped
    [[ -f $wallpaper ]] || return 1
    wallpaper=$(readlink -f "$wallpaper")
    escaped=${wallpaper//\\/\\\\}
    escaped=${escaped//\"/\\\"}
    swaymsg "output * bg \"$escaped\" $SWAY_WALLPAPER_MODE" >/dev/null || return 1
    mkdir -p "$(dirname "$SWAY_WALLPAPER_STATE")"
    printf '%s\n' "$wallpaper" > "$SWAY_WALLPAPER_STATE"
}

# Wallpaper currently shown (last one set by this script, else the default)
sway_current_wallpaper () {
    local wallpaper
    [[ -r $SWAY_WALLPAPER_STATE ]] && wallpaper=$(head -n 1 "$SWAY_WALLPAPER_STATE")
    if [[ -n $wallpaper && -f $wallpaper ]]; then
        printf '%s\n' "$wallpaper"
    else
        printf '%s\n' "$DEFAULT_WALLPAPER"
    fi
}

feh_operation () {
    FEH_WALLPAPER=$(sway_current_wallpaper)
    case $2 in
        "set_default")
            initialization
            if [[ "$(readlink -f "$FEH_WALLPAPER")" != "$(readlink -f "$DEFAULT_WALLPAPER")" ]]; then
                rm -f "$DEFAULT_WALLPAPER"
                cp "$FEH_WALLPAPER" "$DEFAULT_WALLPAPER"
                notify-send -u low "Wallpaper Mode" "Save current as default" --icon=${ICON}
            else
                notify-send -u low "Wallpaper Mode" "Already saved as default wallpaper" --icon=${ICON}
            fi
            ;;
        "save_current")
            if [[ -z $WALLPAPERF ]]; then
                notify-send -u normal "Wallpaper Mode" "WALLPAPERF (favorites directory) is not set" --icon=${ICON}
                return 1
            fi
            cp "$FEH_WALLPAPER" "$WALLPAPERF"
            notify-send -u low "Wallpaper Mode" "Save current to favorite" --icon=${ICON}
            ;;
        "show_current")
            notify-send -u low "Wallpaper Mode" "Current wallpaper: $(basename "$FEH_WALLPAPER")" --icon=${ICON}
            ;;
        "random")
            WALLPAPER=$(find "$3" -name '*.*g' | shuf -n1)
            [[ -n "$WALLPAPER" ]] || return 1
            sway_set_wallpaper "$WALLPAPER"
            notify-send -u low "Wallpaper Mode" "Random from $(basename "$3")\n$WALLPAPER" --icon=${ICON}
            ;;
        "select")
            WALLPAPER=$(find "$3" -name '*.*g' | rofi -config "$ROFI_SELECTOR_CONFIG" -dmenu -i -p "$(basename "$3")")
            if [[ -z "$WALLPAPER" ]]; then
                return
            fi
            sway_set_wallpaper "$WALLPAPER"
            notify-send -u low "Wallpaper Mode" "Select from $(basename "$3")\n$WALLPAPER" --icon=${ICON}
            ;;
        # Feh-ONLY
        "restore_default")
            sway_set_wallpaper "$DEFAULT_WALLPAPER"
            # "quiet" (3rd arg) is used by the sway config startup line
            [[ $3 == quiet ]] || notify-send -u low "Wallpaper Mode" "Restore wallpaper to default" --icon=${ICON}
            ;;
        "restore_last")
            sway_set_wallpaper "$FEH_WALLPAPER"
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
    VARIETY_WALLPAPER="$(cat "$VARIETY_INFO" 2>/dev/null)"
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
            notify-send -u low "Variety Mode" "Random from $(basename "$3")\n$WALLPAPER" --icon=${ICON}
            ;;
        "select")
            WALLPAPER=$(find "$3" -name '*.*g' | rofi -config "$ROFI_SELECTOR_CONFIG" -dmenu -i -p "$(basename "$3")")
            [[ -n "$WALLPAPER" ]] || return
            variety --set="$WALLPAPER"
            notify-send -u low "Variety Mode" "Select from $(basename "$3")\n$WALLPAPER" --icon=${ICON}
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
            feh_operation "$@"
            ;;
        "variety")
            variety_operation "$@"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main program
main "$@"
