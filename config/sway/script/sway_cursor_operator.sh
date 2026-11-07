#!/usr/bin/env bash
# Ported from i3_cursor_operator.sh for sway.
# Replaced X11 tools:
#   - xdotool getwindowfocus/getwindowgeometry/mousemove -> swaymsg -t get_tree (+jq)
#                                                          + swaymsg seat - cursor set X Y
#   - unclutter (cursor auto-hiding)    -> swaymsg seat * hide_cursor 3000 / hide_cursor 0
#   - startup "exec unclutter ..." line -> "seat * hide_cursor 3000" line (commented = off)
#   - mouse-follows-focus via exec appended to ~20 keybindings
#                                       -> native "mouse_warping container"
#   - i3-msg reload                     -> config file edit + direct swaymsg command
# Subcommands are identical to the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

SWAY_CONFIG_DIR="$HOME/.config/sway/config.d"
WINDOW_CONFIG="$SWAY_CONFIG_DIR/sway_window.config"
# The hide_cursor default line is searched in these files, first match wins
HIDE_CURSOR_CONFIGS=(
    "$SWAY_CONFIG_DIR/sway_input_output.config"
    "$SWAY_CONFIG_DIR/sway_startup.config"
)
HIDE_CURSOR_REGEX='^[[:space:]]*#?[[:space:]]*seat[[:space:]]+\*[[:space:]]+hide_cursor[[:space:]]+[0-9]+'
TIMEOUT=3 # Unit: second
TIMEOUT_MS=$((TIMEOUT * 1000))
ICON="$HOME/.config/i3/share/64x64/cursor.png"

show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

show_help_message () {
    echo "Usage:"
    echo "  sway_cursor_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_unclutter]: enable cursor auto-hiding (seat hide_cursor ${TIMEOUT_MS})"
    echo "  [disable_unclutter]: disable cursor auto-hiding"
    echo "  [set_unclutter_as_default]: enable cursor auto-hiding as default"
    echo "  [set_no_unclutter_as_default]: disable cursor auto-hiding as default"
    echo "  [enable_focus_follows_mouse]: set sway focus_follows_mouse to yes"
    echo "  [disable_focus_follows_mouse]: set sway focus_follows_mouse to no"
    echo "  [enable_mouse_follows_focus]: move cursor after focus changes (mouse_warping container)"
    echo "  [disable_mouse_follows_focus]: do not move cursor after focus changes"
    echo "  [move_cursor_inside_window]: move cursor to inside focus window [1-9|top_titlebar]"
}

move_cursor_inside_window () {
    local geometry X0 Y0 WIDTH HEIGHT CENTER_X CENTER_Y BLOCK_W BLOCK_H TX TY
    # Focused node: content area = rect + window_rect offset (falls back to rect for
    # workspaces/containers without a window)
    geometry=$(swaymsg -t get_tree -r | jq -r '
        [.. | objects | select(.focused? == true)][0]
        | if (.window_rect.width // 0) > 0 then
            "\(.rect.x + .window_rect.x) \(.rect.y + .window_rect.y) \(.window_rect.width) \(.window_rect.height)"
          else
            "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"
          end')
    read -r X0 Y0 WIDTH HEIGHT <<< "$geometry"
    [[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]] || return
    CENTER_X=$((WIDTH / 2))
    CENTER_Y=$((HEIGHT / 2))
    BLOCK_W=$((WIDTH / 3))
    BLOCK_H=$((HEIGHT / 3))
    case $1 in
        "1") TX=$((CENTER_X - BLOCK_W)); TY=$((CENTER_Y - BLOCK_H)) ;;
        "2") TX=$CENTER_X;               TY=$((CENTER_Y - BLOCK_H)) ;;
        "3") TX=$((CENTER_X + BLOCK_W)); TY=$((CENTER_Y - BLOCK_H)) ;;
        "4") TX=$((CENTER_X - BLOCK_W)); TY=$CENTER_Y ;;
        "5"|"") TX=$CENTER_X;            TY=$CENTER_Y ;;
        "6") TX=$((CENTER_X + BLOCK_W)); TY=$CENTER_Y ;;
        "7") TX=$((CENTER_X - BLOCK_W)); TY=$((CENTER_Y + BLOCK_H)) ;;
        "8") TX=$CENTER_X;               TY=$((CENTER_Y + BLOCK_H)) ;;
        "9") TX=$((CENTER_X + BLOCK_W)); TY=$((CENTER_Y + BLOCK_H)) ;;
        "top_titlebar")
            TX=$CENTER_X
            TY=$((CENTER_Y - HEIGHT / 2 - 10))
            ;;
        *)
            return
    esac
    swaymsg seat - cursor set $((X0 + TX)) $((Y0 + TY)) > /dev/null
}

# Replace the first line matching $2 in file $1 with $3 (returns 1 if no match)
replace_config_line () {
    local file=$1 regex=$2 line=$3 nr
    [[ -w "$file" ]] || return 1
    nr=$(grep -nE "$regex" "$file" | head -n1 | cut -d: -f1)
    [[ -n "$nr" ]] || return 1
    # Escape sed replacement metacharacters
    line=$(printf '%s' "$line" | sed -e 's/[\/&]/\\&/g')
    sed -i "${nr} s/.*/${line}/" "$file"
}

set_hide_cursor_default () {
    local new_line=$1 config
    for config in "${HIDE_CURSOR_CONFIGS[@]}"; do
        replace_config_line "$config" "$HIDE_CURSOR_REGEX" "$new_line" && return 0
    done
    notify-send -u critical "Mouse Mode" "No 'seat * hide_cursor N' line found in sway_input_output.config / sway_startup.config" --icon=${ICON}
    return 1
}

current_mouse_warping () {
    grep -E '^[[:space:]]*mouse_warping[[:space:]]' "$WINDOW_CONFIG" 2>/dev/null | head -n1 | awk '{print $2}'
}

current_focus_follows_mouse () {
    grep -E '^[[:space:]]*focus_follows_mouse[[:space:]]' "$WINDOW_CONFIG" 2>/dev/null | head -n1 | awk '{print $2}'
}

set_window_option () {
    # set_window_option <option> <value>: persist in sway_window.config and apply now
    replace_config_line "$WINDOW_CONFIG" "^[[:space:]]*#?[[:space:]]*$1[[:space:]]" "$1 $2"
    swaymsg "$1 $2" > /dev/null
}

cursor_operation () {
    local warp
    case $1 in
        "enable_unclutter")
            notify-send -u low "Mouse Mode" "Cursor auto-hiding (hide_cursor) is enabled" --icon=${ICON}
            swaymsg "seat * hide_cursor ${TIMEOUT_MS}" > /dev/null
            ;;
        "disable_unclutter")
            notify-send -u low "Mouse Mode" "Cursor auto-hiding (hide_cursor) is disabled" --icon=${ICON}
            swaymsg "seat * hide_cursor 0" > /dev/null
            ;;
        "set_unclutter_as_default")
            set_hide_cursor_default "seat * hide_cursor ${TIMEOUT_MS}" &&
                notify-send -u "low" "Mouse Mode" "Set cursor auto-hiding as default" --icon=${ICON}
            ;;
        "set_no_unclutter_as_default")
            set_hide_cursor_default "#seat * hide_cursor ${TIMEOUT_MS}" &&
                notify-send -u "low" "Mouse Mode" "Set no cursor auto-hiding as default" --icon=${ICON}
            ;;
        "enable_focus_follows_mouse")
            set_window_option focus_follows_mouse yes
            # Keep mouse-follows-focus (container) if it is on, else warp on output change
            warp=$(current_mouse_warping)
            [[ "$warp" == container ]] || set_window_option mouse_warping output
            ;;
        "disable_focus_follows_mouse")
            set_window_option focus_follows_mouse no
            warp=$(current_mouse_warping)
            [[ "$warp" == container ]] || set_window_option mouse_warping none
            ;;
        "enable_mouse_follows_focus")
            set_window_option mouse_warping container
            notify-send -u low "Mouse Mode" "Mouse follows focus (mouse_warping container)" --icon=${ICON}
            ;;
        "disable_mouse_follows_focus")
            if [[ "$(current_focus_follows_mouse)" == no ]]; then
                set_window_option mouse_warping none
            else
                set_window_option mouse_warping output
            fi
            notify-send -u low "Mouse Mode" "Mouse no longer follows focus" --icon=${ICON}
            ;;
        "move_cursor_inside_window")
            move_cursor_inside_window "$2"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
cursor_operation "$@"
