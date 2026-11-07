#!/usr/bin/env bash
# Ported from i3_flashfocus_operator.sh for sway.
# Replaced X11 tools:
#   - waiting for picom before start    -> dropped (flashfocus drives sway's own opacity via IPC)
#   - session age via xprop -root I3_PID -> age of the sway process (pgrep -x sway)
# Subcommands are identical to the i3 version: start | stop | restart.
#
# Start/stop flashfocus reliably (login, Super+Shift+C f, flameshot pause).
# - flashfocus.yml is a symlink chosen with "Set default flashfocus" and is not
#   tracked in git, so it disappears after a fresh clone or a cleanup.
# - When it exits, its error goes to $LOG and a notification.
# - A flashfocus left over from a previous login keeps running without a
#   compositor connection; "start" replaces it (see stop_stale_flashfocus).

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
FLASHFOCUS_DIR="$HOME/.config/flashfocus"
LOG="${XDG_RUNTIME_DIR:-/tmp}/flashfocus.log"
ICON="$HOME/.config/i3/share/64x64/notification.png"

show_help_message () {
    echo "Usage: $0 [start|stop|restart]"
    echo "  start:   start flashfocus unless it is running"
    echo "  stop:    stop flashfocus"
    echo "  restart: stop, then start"
}

ensure_config () {
    [[ -f "$FLASHFOCUS_DIR/flashfocus.yml" ]] && return 0
    mkdir -p "$FLASHFOCUS_DIR"
    ln -sfn "$FLASHFOCUS_DIR/flashfocus_transparency.yml" "$FLASHFOCUS_DIR/flashfocus.yml"
    notify-send -u normal -i "$ICON" "Flashfocus" \
        "flashfocus.yml was missing; set the default to transparency. Change it with Super+Shift+C, f, s" || true
}

running () {
    pgrep -u "$USER" -x flashfocus >/dev/null
}

# Seconds since the current sway started (age of the Wayland session).
sway_age () {
    local pid
    pid=$(pgrep -u "$USER" -o -x sway)
    [[ -n $pid ]] && ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' '
}

# A flashfocus older than the current sway belongs to a previous login; stop it,
# otherwise "start" sees it running and does nothing.
stop_stale_flashfocus () {
    local session_age pid age stale=()
    session_age=$(sway_age)
    [[ $session_age =~ ^[0-9]+$ ]] || return 0
    for pid in $(pgrep -u "$USER" -x flashfocus); do
        age=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
        [[ $age =~ ^[0-9]+$ ]] && ((age > session_age)) && stale+=("$pid")
    done
    ((${#stale[@]})) || return 0
    kill "${stale[@]}" 2>/dev/null
    sleep 0.5
    kill -KILL "${stale[@]}" 2>/dev/null
    return 0
}

stop_flashfocus () {
    local i
    killall -q -u "$USER" flashfocus || return 0
    for i in {1..30}; do
        running || return 0
        sleep 0.1
    done
    killall -q -KILL -u "$USER" flashfocus
}

start_flashfocus () {
    stop_stale_flashfocus
    running && return 0
    ensure_config
    # setsid: not tied to this script; output kept for the failure notification
    setsid -f "$(dirname "$0")/sway_run.sh" flashfocus >"$LOG" 2>&1 </dev/null
    sleep 2
    if ! running; then
        notify-send -u critical -i "$ICON" "Flashfocus exited" \
            "$(tail -n 5 "$LOG" 2>/dev/null)"$'\n'"(full log: $LOG)" || true
        return 1
    fi
}

case $1 in
    "start") start_flashfocus ;;
    "stop") stop_flashfocus ;;
    "restart") stop_flashfocus; start_flashfocus ;;
    "-h"|"--help") show_help_message ;;
    *) show_help_message; exit 1 ;;
esac
