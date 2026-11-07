#!/usr/bin/env bash
# ~/.config/sway/script/sway_screenshot_operator.sh
# Ported from i3_flameshot_operator.sh for sway.
# Replaced X11 tools:
#   - flameshot gui/full/--region       -> grim (+ slurp for regions, + swappy to annotate)
#   - xdotool getactivewindow geometry  -> swaymsg -t get_tree (focused .rect)
#   - xdotool selectwindow              -> slurp -r over the visible window rects
#   - xdotool get_desktop (screenN)     -> focused output name (grim -o)
#   - xclip (flameshot clipboard)       -> wl-copy
# GUI (PrtScn): the tool set by `set $default_screenshot_tool grim|flameshot` in
#   ~/.config/sway/config (SCREENSHOT_GUI=... overrides it for one call).
#   grim:      slurp region (dimmed background, like flameshot) -> grim -> satty or swappy
#   flameshot: flameshot gui. test_v3: flameshot accepted every request but never showed
#              its overlay on sway, so grim is the default; flameshot failing falls back.
#   `start_daemon` (sway_startup.config) starts the flameshot tray daemon only when the
#   tool is flameshot, with QT_QPA_PLATFORM=wayland so Qt does not use XWayland.
# Errors from grim/slurp/flameshot are shown as notifications and logged to
#   $XDG_RUNTIME_DIR/sway_screenshot.log (test_v2: PrtScn failed silently).
#
# Every capture is saved to ~/Pictures/Screenshot_<date>.png and copied to the clipboard.
# Interactive modes (GUI, select_window, active_window, current_screen) open the image in
# swappy afterwards when it is installed (like flameshot's editor); `full` saves directly.
# Set SCREENSHOT_EDIT=0 to never open swappy.
#
# Usage: sway_screenshot_operator.sh GUI|select_window|active_window|current_screen|full [keep|hide]

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"

SAVE_DIR="$HOME/Pictures"
SWAY_CONFIG="$HOME/.config/sway/config"
ICON="$HOME/.config/i3/share/64x64/wrench.png"
SCREENSHOT_EDIT="${SCREENSHOT_EDIT:-1}"
SCREENSHOT_GUI="${SCREENSHOT_GUI:-}"
# Dimmed background + white border + size label (slurp's default overlay is easy to miss)
SLURP_ARGS=(-d -b '#00000066' -c '#ffffffcc' -s '#00000000' -w 2)

screenshot_tool () {
    local tool=${SCREENSHOT_GUI:-$(awk '$1 == "set" && $2 == "$default_screenshot_tool" {print $3; exit}' "$SWAY_CONFIG")}
    echo "${tool:-grim}"
}

start_flameshot_daemon () {
    pgrep -u "$USER" -x flameshot > /dev/null && return 0
    command -v flameshot > /dev/null || return 1
    QT_QPA_PLATFORM=wayland XDG_CURRENT_DESKTOP=sway setsid -f flameshot >> "$LOG" 2>&1 < /dev/null
    sleep 1
}
LOG="${XDG_RUNTIME_DIR:-/tmp}/sway_screenshot.log"

# Run a capture command; on failure notify with its last error line
run_logged () {
    local status
    echo "[$(date +%T)] $*" >> "$LOG"
    "$@" 2>> "$LOG"
    status=$?
    if [[ $status -ne 0 ]]; then
        notify-send -u normal "Screenshot failed: $1" "$(tail -n 1 "$LOG")\n(log: ${LOG})" --icon="${ICON}"
    fi
    return $status
}

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_screenshot_operator.sh [options] [titlebar_border_option]"
    echo ""
    echo "OPTIONS"
    echo "  [active_window]: get active window (current focus) snapshot"
    echo "  [select_window]: select window to snapshot"
    echo "  [current_screen]: get current screen snapshot"
    echo "  [full]: get snapshot of all screens"
    echo "  [GUI]: select a region (slurp) and annotate it (swappy)"
    echo ""
    echo "TITLEBAR_BORDER_OPTION"
    echo "  [keep]: keep titlebar and border"
    echo "  [hide]: hide titlebar and border temporarily"
}

# Visible windows as slurp boxes: "x,y wxh con_id"
visible_window_boxes () {
    swaymsg -t get_tree -r | jq -r '
        .. | objects
        | select((.type == "con" or .type == "floating_con") and .pid != null and .visible == true)
        | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height) \(.id)"'
}

select_region () {
    local boxes selection
    case "$1" in
        "active_window")
            # .rect = window incl. border, without titlebar (absolute layout coordinates)
            REGION=$(swaymsg -t get_tree -r | jq -r '
                first(.. | objects | select(.focused? == true and .pid != null))
                | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')
            [[ -n $REGION && $REGION != null* ]] || return 1
            ;;
        "select_window")
            # Let the user click a window (slurp -r restricts to the given boxes)
            boxes=$(visible_window_boxes)
            [[ -n $boxes ]] || return 1
            selection=$(printf '%s\n' "$boxes" | slurp "${SLURP_ARGS[@]}" -r -f '%x,%y %wx%h') || return 1
            REGION=$selection
            ;;
        "current_screen")
            OUTPUT=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name')
            [[ -n $OUTPUT ]] || return 1
            REGION="output"
            ;;
        "full")
            REGION="full"
            ;;
        "GUI")
            REGION=""
            ;;
        # Print usage
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit 1
    esac
}

# Save "$1" to clipboard and notify
finish_capture () {
    local file=$1
    [[ -s $file ]] || return 1
    command -v wl-copy > /dev/null && wl-copy --type image/png < "$file"
    if [[ $SCREENSHOT_EDIT != 0 && $2 == edit ]]; then
        # Annotation editor (flameshot's editor on i3): satty if installed, else swappy.
        # Both overwrite the saved file on save.
        if command -v satty > /dev/null; then
            satty --filename "$file" --output-filename "$file" --early-exit --copy-command wl-copy
        elif command -v swappy > /dev/null; then
            swappy -f "$file" -o "$file"
        fi
        command -v wl-copy > /dev/null && wl-copy --type image/png < "$file"
    fi
    notify-send -u low "Screenshot" "Saved to ${file/#$HOME/\~} and copied to clipboard" --icon="${ICON}"
}

take_screenshot () {
    local file
    mkdir -p "$SAVE_DIR"
    file="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

    # PrtScn / GUI with flameshot selected
    if [[ -z ${REGION} && $(screenshot_tool) == flameshot ]] && command -v flameshot > /dev/null; then
        start_flameshot_daemon
        run_logged flameshot gui -p "$SAVE_DIR" && return 0
        command -v grim > /dev/null && command -v slurp > /dev/null || return 1
        notify-send -u low "Screenshot" "flameshot failed, using grim + slurp" --icon="${ICON}"
    fi

    if ! command -v grim > /dev/null || ! command -v slurp > /dev/null; then
        local missing=""
        command -v grim > /dev/null || missing+=" grim"
        command -v slurp > /dev/null || missing+=" slurp"
        notify-send -u normal "sway_screenshot_operator.sh" "Not installed:${missing}\nInstall: sudo apt install grim slurp swappy  (or install_sway.sh, wayland_tool_packages)\nPATH=${PATH}" --icon="${ICON}"
        return 1
    fi

    case $REGION in
        "")
            local area
            # slurp exits 1 when the selection is cancelled with Escape: not an error
            area=$(slurp "${SLURP_ARGS[@]}" 2>> "$LOG") || return 1
            run_logged grim -g "$area" "$file" && finish_capture "$file" edit
            ;;
        full)
            run_logged grim "$file" && finish_capture "$file"
            ;;
        output)
            run_logged grim -o "$OUTPUT" "$file" && finish_capture "$file" edit
            ;;
        *)
            run_logged grim -g "$REGION" "$file" && finish_capture "$file" edit
            ;;
    esac
}

config_default () {
    awk -v key="\$$1" '$1 == "set" && $2 == key {print $3; exit}' "$SWAY_CONFIG"
}

main () {

    # Login: start the flameshot tray daemon only when flameshot is the selected tool
    if [[ $1 == start_daemon ]]; then
        [[ $(screenshot_tool) == flameshot ]] && start_flameshot_daemon
        return 0
    fi

    # Hide titlebar and border temporarily
    if [[ $2 == 'hide' ]]; then
        swaymsg '[all] border pixel 0' > /dev/null
        # let sway re-layout before measuring geometry
        sleep 0.2
    fi

    # Pause flashfocus
    FLASHFOCUS_ON=0
    if pgrep -x flashfocus > /dev/null; then
        killall flashfocus
        FLASHFOCUS_ON=1
    fi

    # A cancelled window selection must not open a second screenshot prompt.
    SCREENSHOT_STATUS=0
    if select_region "$1"; then
        take_screenshot
        SCREENSHOT_STATUS=$?
    else
        SCREENSHOT_STATUS=1
    fi

    if [[ "${FLASHFOCUS_ON}" == 1 ]]; then
        if [[ -x $SWAY_SCRIPT/sway_flashfocus_operator.sh ]]; then
            swaymsg -- exec "$SWAY_SCRIPT/sway_flashfocus_operator.sh start" > /dev/null
        else
            swaymsg -- exec "$HOME/.config/sway/script/sway_run.sh flashfocus" > /dev/null
        fi
    fi

    # Restore titlebar/border to defaults (same variables as the i3 config)
    if [[ $2 == 'hide' ]]; then
        DEFAULT_WIDTH=$(config_default default_border_width)
        DEFAULT_STYLE=$(config_default default_titlebar_style)
        DEFAULT_FLOATING_STYLE=$(config_default default_floating_titlebar_style)
        swaymsg "[tiling] border ${DEFAULT_STYLE:-pixel} ${DEFAULT_WIDTH:-2}; \
                 [floating] border ${DEFAULT_FLOATING_STYLE:-pixel} ${DEFAULT_WIDTH:-2}" > /dev/null
    fi

    return "$SCREENSHOT_STATUS"

}

# Main
main "$@"
