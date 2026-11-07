#!/usr/bin/env bash
# Ported from i3_kdeconnect_operator.sh for sway.
# Replaced X11 tools:
#   - i3_kdeconnect_pointer_daemon.py (i3ipc, matched X class) -> sway_kdeconnect_pointer_daemon.py
#     (i3ipc over SWAYSOCK, matches Wayland app_id or XWayland class)
#   - picom invert-color-include (pointer_invert_on/off) -> not available: sway has no
#     compositor-side colour inversion (stubbed)
# NOTE: KDE Connect *remote input* (phone as mouse/keyboard, presenter pointer) on
# wlroots needs the xdg-desktop-portal RemoteDesktop interface, which
# xdg-desktop-portal-wlr does not implement. On sway it may only work for the
# XWayland/fake-input path or not at all; file transfer, notifications, clipboard, etc. work.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
DAEMON="${SWAY_SCRIPT}/sway_kdeconnect_pointer_daemon.py"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_kdeconnect_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_pointer]: enable pointer daemon"
    echo "  [disable_pointer]: disable pointer daemon"
    echo "  [reload_pointer]: reload pointer daemon"
    echo "  [pointer_invert_on]: invert pointer color (not supported on sway)"
    echo "  [pointer_invert_off]: restore pointer color (not supported on sway)"
    echo "  [reload_kdeconnect]: reload kdeconnect daemon"
}

stop_daemon () {
    pkill -f "python3 ${DAEMON}" &> /dev/null || true
}

kdeconnect_operation () {
    ICON="$HOME/.config/i3/share/64x64/cursor.png"
    case $1 in
        "reload_kdeconnect")
            notify-send -u "low" "sway kdeconnect" "Reload Kdeconnect daemon" --icon=${ICON}
            killall kdeconnectd
            kdeconnect-cli --refresh
            ;;
        "enable_pointer")
            notify-send -u "low" "sway kdeconnect" "Pointer daemon is enabled" --icon=${ICON}
            python3 "${DAEMON}"
            ;;
        "disable_pointer")
            notify-send -u "low" "sway kdeconnect" "Pointer daemon is disabled" --icon=${ICON}
            stop_daemon
            ;;
        "reload_pointer")
            notify-send -u "low" "sway kdeconnect" "Reload pointer daemon" --icon=${ICON}
            stop_daemon
            python3 "${DAEMON}"
            ;;
        "pointer_invert_on"|"pointer_invert_off")
            notify-send -u normal "sway_kdeconnect_operator.sh" \
                "$1: not supported on sway/Wayland – picom colour inversion has no sway equivalent" --icon=${ICON}
            exit 1
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
kdeconnect_operation "$1"
