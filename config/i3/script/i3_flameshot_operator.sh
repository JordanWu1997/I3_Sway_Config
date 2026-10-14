#!/usr/bin/env bash

# Modified from
# -- https://github.com/flameshot-org/flameshot/issues/273

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_flameshot_operator.sh [options] [titlebar_border_option]"
    echo ""
    echo "OPTIONS"
    echo "  [active_window]: get active window (current focus) snapshot"
    echo "  [select_window]: select window to snapshot"
    echo "  [current_screen]: get current screen snapshot"
    echo "  [full]: get snapshot of all screens"
    echo "  [GUI]: open flameshot GUI"
    echo ""
    echo "TITLEBAR_BORDER_OPTION"
    echo "  [hide]: hide titlebar and border temporarily"
}

select_region () {
    case "$1" in
        "active_window")
            # Get active window geometry
            eval $(xdotool getactivewindow getwindowgeometry --shell)
            # MINUS shadow area
            WIDTH=$((WIDTH - FULLWIDTH))
            Y=$((Y + HALFWIDTH))
            HEIGHT=$((HEIGHT - FULLHEIGHT))
            X=$((X + HALFHEIGHT))
            # MINUS border width
            CURRENT_WD_BORDER_WIDTH=$(i3-msg -t get_tree | jq '.. | select(.focused? == true) | .current_border_width')
            Y=$((Y - CURRENT_WD_BORDER_WIDTH))
            X=$((X - CURRENT_WD_BORDER_WIDTH))
            # Region
            REGION="${WIDTH}x${HEIGHT}+${X}+${Y}"
            ;;
        "select_window")
            # Let the user select a window and get its geometry
            SELECTED_WINDOW_ID=$(xdotool selectwindow) || return 1
            eval "$(xdotool getwindowgeometry --shell "$SELECTED_WINDOW_ID")" || return 1
            # MINUS border width
            CURRENT_WD_BORDER_WIDTH=$(i3-msg -t get_tree | jq -r --argjson wid "$SELECTED_WINDOW_ID" 'first(.. | objects | select(.window? == $wid) | .current_border_width) // 0')
            Y=$((Y - CURRENT_WD_BORDER_WIDTH))
            X=$((X - CURRENT_WD_BORDER_WIDTH))
            # Region
            REGION="${WIDTH}x${HEIGHT}+${X}+${Y}"
            ;;
        "current_screen")
            # Get current screen
            SCREEN=$(xdotool get_desktop)
            REGION="screen${SCREEN}"
            ;;
        "full")
            REGION="full"
            ;;
        "GUI")
            ;;
        # Print usage
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

main () {

    # Hide titlebar and border temporarily
    if [[ $2 == 'hide' ]]; then
        i3-msg [con_mark="^.*"] border pixel 0
    fi

    # Pause flashfocus
    FLASHFOCUS_ON=0
    if pgrep -x flashfocus >/dev/null; then
        killall flashfocus
        FLASHFOCUS_ON=1
    fi

    # A cancelled window selection must not open a second screenshot prompt.
    SCREENSHOT_STATUS=0
    if select_region "$1"; then
        if [[ -z "${REGION}" ]]; then
            flameshot gui -p "$HOME/Pictures"
        elif [[ "${REGION}" == 'full' ]]; then
            flameshot full -p "$HOME/Pictures"
        else
            flameshot gui --region "${REGION}" -p "$HOME/Pictures"
        fi
        SCREENSHOT_STATUS=$?
    else
        SCREENSHOT_STATUS=1
    fi

    if [[ "${FLASHFOCUS_ON}" == 1 ]]; then
        i3-msg exec flashfocus
    fi

    # Restore titlebar/border to defaults
    if [[ $2 == 'hide' ]]; then
        DEFAULT_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
        DEFAULT_STYLE=$(awk '$0~/default_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
        DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
        i3-msg "[all] border ${DEFAULT_STYLE} ${DEFAULT_WIDTH}; \
                [floating] border ${DEFAULT_FLOATING_STYLE} ${DEFAULT_WIDTH}; \
                [tiling_from='user'] border ${DEFAULT_STYLE} ${DEFAULT_WIDTH}"
    fi

    return "$SCREENSHOT_STATUS"

}

# Main
main "$@"
