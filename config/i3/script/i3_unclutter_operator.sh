#!/usr/bin/env bash

STARTUP_CONFIG="$HOME/.config/i3/config.d/i3_startup.config"
COL_UNCLUTTER=$(awk '$0~/exec --no-startup-id unclutter/{print NR}' ${STARTUP_CONFIG})
UNCLUTTER_OPTION="--start-hidden"
TIMEOUT=3 # Unit: second

show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

show_help_message () {
    echo "Usage:"
    echo "  i3_autotiling_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_unclutter]: enable unclutter"
    echo "  [disable_unclutter]: enable unclutter"
    echo "  [set_unclutter_as_default]: enable unclutter as default"
    echo "  [set_no_unclutter_as_default]: disable unclutter as default"
}

unclutter_operation () {
    case $1 in
        "enable_unclutter")
            notify-send -u low "Mouse Mode" "Cursor auto-hiding (unclutter) is enabled"
            unclutter --timeout ${TIMEOUT} ${UNCLUTTER_OPTION}
            ;;
        "disable_unclutter")
            notify-send -u low "Mouse Mode" "Cursor auto-hiding (unclutter) is disabled"
            killall unclutter
            ;;
        "set_unclutter_as_default")
            sed -i "$COL_UNCLUTTER s/.*/exec \-\-no\-startup\-id unclutter \-\-timeout ${TIMEOUT} ${UNCLUTTER_OPTION}/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Mouse Mode" "Set cursor auto-hiding (unclutter) as default"
            ;;
        "set_no_unclutter_as_default")
            sed -i "$COL_UNCLUTTER s/.*/\#exec \-\-no\-startup\-id unclutter \-\-timeout ${TIMEOUT} ${UNCLUTTER_OPTION}/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Mouse Mode" "Set no cursor auto-hiding (unclutter) as default"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
unclutter_operation $1
