#!/usr/bin/env bash

STARTUP_CONFIG="$HOME/.config/i3/config.d/i3_startup.config"
COL_AUTOTILING=$(awk '$0~/exec_always --no-startup-id autotiling/{print NR}' ${STARTUP_CONFIG})

show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

show_help_message () {
    echo "Usage:"
    echo "  i3_autotiling_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_dwindling]: enable dwindling layout"
    echo "  [enable_master_stack]: enable master-stack layout (require autotiling > 1.8)"
    echo "  [disable_dwindling]: disable dwindling layout"
    echo "  [disable_master_stack]: disable master-stack layout"
    echo "  [set_dwindling_as_default]: set dwindling layout as default"
    echo "  [set_master_stack_as_default]: set master-stack layout as default"
    echo "  [set_no_autotiling_as_default]: do not set autotiling layout as default"
}

autotiling_operation () {
    case $1 in
        "disable_autotiling")
            notify-send -u "low" "i3 Autotiling" "i3 Autotiling is disabled"
            killall autotiling
            ;;
        "enable_dwindling")
            killall autotiling
            notify-send -u "low" "i3 Autotiling" "i3 dwindling layout is enabled"
            autotiling
            ;;
        "enable_master_stack")
            killall autotiling
            notify-send -u "low" "i3 Autotiling" "i3 master-stack layout is enabled"
            autotiling --limit 2
            ;;
        "set_dwindling_as_default")
            sed -i "$COL_AUTOTILING s/.*/exec_always \-\-no\-startup\-id autotiling/" "${STARTUP_CONFIG}"
            notify-send -u "low" "i3 Autotiling" "Set dwindling layout as default"
            ;;
        "set_master_stack_as_default")
            sed -i "$COL_AUTOTILING s/.*/exec_always \-\-no\-startup\-id autotiling \-\-limit 2/" "${STARTUP_CONFIG}"
            notify-send -u "low" "i3 Autotiling" "Set master-stack layout as default"
            ;;
        "set_no_autotiling_as_default")
            sed -i "$COL_AUTOTILING s/.*/\#exec_always \-\-no\-startup\-id autotiling/" "${STARTUP_CONFIG}"
            notify-send -u "low" "i3 Autotiling" "Set no auto-tiling layout as default"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
autotiling_operation $1
