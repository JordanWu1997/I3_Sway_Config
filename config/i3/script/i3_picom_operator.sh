#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_picom_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start picom with default picom configuration"
    echo "  [transparency]: start picom with transparency configuration"
    echo "  [blur]: start picom with blur configuration"
    echo "  [restart_running]: restart picom with its current configuration"
    echo "  [after_i3_restart]: restart_running, but only after an i3 restart (exec_always)"
}

PICOM_DIR="$HOME/.config/picom"
ICON="$HOME/.config/i3/share/64x64/notification.png"

# picom.conf is a symlink chosen with "Set default picom" (Super+Shift+C, p, s).
# It is not tracked in git, so it is missing after a fresh clone or a cleanup.
# Started without a config file, picom runs with built-in defaults: the process
# is there, but there is no transparency, blur or shadow. Never let that happen.
default_config () {
    if [[ -f "$PICOM_DIR/picom.conf" ]]; then
        echo "$PICOM_DIR/picom.conf"
        return
    fi
    ln -sfn "$PICOM_DIR/picom_transparency.conf" "$PICOM_DIR/picom.conf"
    notify-send -u normal -i "$ICON" "Picom" \
        "picom.conf was missing; set the default to transparency. Change it with Super+Shift+C, p, s" || true
    echo "$PICOM_DIR/picom_transparency.conf"
}

# killall only sends SIGTERM. A picom that is still shutting down owns the
# compositor slot, so a new one started right away exits ("another composite
# manager is already running"). Wait until the old one is gone.
stop_picom () {
    local i
    killall -q -u "$USER" picom || return 0
    for i in {1..30}; do
        pgrep -u "$USER" -x picom >/dev/null || return 0
        sleep 0.1
    done
    killall -q -KILL -u "$USER" picom
    sleep 0.2
}

start_picom () {
    local config=$1
    stop_picom
    i3-msg -- exec --no-startup-id "picom --config '$config' --daemon" >/dev/null
    sleep 1
    if ! pgrep -u "$USER" -x picom >/dev/null; then
        notify-send -u critical -i "$ICON" "Picom failed to start" \
            "Run in a terminal to see why: picom --config $config" || true
        return 1
    fi
}

# Restart picom with the config it is running now (no-op when picom is not running)
restart_running () {
    local cmdline config
    cmdline=$(pgrep -u "$USER" -a -x picom | head -n 1)
    [[ -n $cmdline ]] || return 0
    config=$(sed -n 's/.* --config \([^ ]*\).*/\1/p' <<< "$cmdline")
    start_picom "${config:-$(default_config)}"
}

# Run from i3 with exec_always. i3 keeps its PID across a restart (it re-execs
# itself), so the same PID as last time means "restart", a new one means "login".
#
# Why restart picom: on an i3 restart, i3 hands every window back to the root
# window and the new i3 wraps each one in a new frame. This picom fork does not
# match its rules again for a window moved into a new frame, so windows opened
# before the restart lose their opacity/blur rules and transparency, while new
# windows are fine. A fresh picom scans every window from scratch.
after_i3_restart () {
    local marker="${XDG_RUNTIME_DIR:-/tmp}/i3_picom_last_i3_pid" pid
    pid=$(xprop -root -notype I3_PID 2>/dev/null | awk '{print $NF}')
    [[ $pid =~ ^[0-9]+$ ]] || pid=$(pgrep -u "$USER" -o -x i3)
    [[ -n $pid ]] || return 0
    if [[ -f $marker && $(< "$marker") == "$pid" ]]; then
        sleep 1    # let i3 finish re-adopting the windows
        restart_running
    fi
    echo "$pid" > "$marker"
}

picom_operation () {
    case $1 in
        "restart_running")
            restart_running
            ;;
        "after_i3_restart")
            after_i3_restart
            ;;
        "default")
            start_picom "$(default_config)"
            ;;
        "transparency")
            start_picom "$PICOM_DIR/picom_transparency.conf"
            ;;
        "blur")
            start_picom "$PICOM_DIR/picom_blur.conf"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
picom_operation $1
