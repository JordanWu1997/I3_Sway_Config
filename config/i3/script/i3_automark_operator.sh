#!/usr/bin/env bash

automark_operation () {
    case $1 in
        "enable")
            notify-send -u "low" "i3 Automark" "i3 automark is enabled"
            python3 $I3_SCRIPT/i3_automark.py
            ;;
        "disable")
            notify-send -u "low" "i3 Automark" "i3 automark is disabled"
            kill $(ps -aux | grep "python3 $I3_SCRIPT/i3_automark.py")
            ;;
        *)
            echo $0
    esac
}

# Main
automark_operation $1
