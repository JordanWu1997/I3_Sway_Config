#!/usr/bin/env bash

show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

show_help_message () {
    echo "Usage:"
    echo "  i3_autotiling_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_dwindling]: enable dwindling autotiling"
    echo "  [disable_dwindling]: disable dwindling autotiling"
}

autotiling_operation () {
    case $1 in
        "enable_dwindling")
            notify-send -u "low" "i3 Autotiling" "i3 dwindling autotiling is enabled"
            python $PYTHON_BIN/autotiling
            ;;
        "disable_dwindling")
            notify-send -u "low" "i3 Autotiling" "i3 dwindling autotiling is disabled"
            kill $(ps -aux | grep "python $PYTHON_BIN/autotiling")
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
