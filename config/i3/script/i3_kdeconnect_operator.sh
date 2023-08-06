#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_kdeconnect_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_pointer]: enable pointer daemon"
    echo "  [disable_pointer]: disable pointer daemon"
    echo "  [reload_pointer]: reload pointer daemon"
}

kdeconnect_operation () {
    case $1 in
        "enable_pointer")
            notify-send -u "low" "i3 kdeconnect" "Pointer daemon is enabled"
            python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py
            ;;
        "disable_pointer")
            notify-send -u "low" "i3 kdeconnect" "Pointer daemon is disabled"
            ps -aux | grep "python3 ${I3_SCRIPT}/i3_kdeconnect_pointer_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            ;;
        "reload_pointer")
            notify-send -u "low" "i3 kdeconnect" "Reload pointer daemon"
            ps -aux | grep "python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
kdeconnect_operation $1
