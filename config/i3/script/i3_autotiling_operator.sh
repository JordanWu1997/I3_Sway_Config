#!/usr/bin/env bash

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
            echo $0
    esac
}

# Main
autotiling_operation $1
