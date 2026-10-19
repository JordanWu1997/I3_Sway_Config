#!/usr/bin/env bash

# One read-only System view. Each component reports its own current state.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"

component_status() {
    local script=$1 fallback=$2
    if [[ -x $SCRIPT_DIR/$script ]]; then
        "$SCRIPT_DIR/$script" status || printf '%s | unavailable\n' "$fallback"
    else
        printf '%s | unavailable\n' "$fallback"
    fi
}

notification_status() {
    local paused
    paused=$(dunstctl is-paused 2>/dev/null) || {
        printf 'Notifications | unavailable\n'
        return
    }
    case $paused in
        true) printf 'Notifications | paused\n' ;;
        false) printf 'Notifications | active\n' ;;
        *) printf 'Notifications | unknown\n' ;;
    esac
}

collect_status() {
    component_status i3_battery_notification.sh Battery
    component_status i3_network_operator.sh Network
    component_status i3_bluetooth_operator.sh Bluetooth
    component_status i3_RF_device_operator.sh 'Radio blocks'
    component_status i3_pulseaudio_notification.sh Audio
    notification_status
}

process_status() {
    local label=$1 name=$2
    if pgrep -u "$(id -u)" -x "$name" >/dev/null 2>&1; then
        printf '%s | running\n' "$label"
    else
        printf '%s | stopped\n' "$label"
    fi
}

script_status() {
    local label=$1 script=$2 target pid arg resolved
    local -a argv
    target=$(readlink -f -- "$SCRIPT_DIR/$script") || {
        printf '%s | stopped\n' "$label"
        return
    }
    # pgrep -f also matches shells whose command string merely mentions the
    # filename. Require an actual process argument naming this script instead.
    while IFS= read -r pid; do
        [[ -r /proc/$pid/cmdline ]] || continue
        mapfile -d '' -t argv < "/proc/$pid/cmdline" 2>/dev/null || continue
        for arg in "${argv[@]:0:2}"; do
            [[ $arg == "$script" || $arg == */"$script" ]] || continue
            resolved=$(readlink -f -- "$arg") || continue
            if [[ $resolved == "$target" ]]; then
                printf '%s | running\n' "$label"
                return
            fi
        done
    done < <(pgrep -u "$(id -u)" -f "$script" || true)
    printf '%s | stopped\n' "$label"
}

collect_health() {
    process_status 'Screen lock helper' xss-lock
    process_status 'Notifications' dunst
    process_status 'Clipboard manager' parcellite
    process_status 'Network tray' nm-applet
    process_status 'Bluetooth tray' blueman-applet
    process_status 'Input method' ibus-daemon
    process_status 'Compositor' picom
    process_status 'Autotiling' autotiling
    script_status 'Window automark' i3_automark_daemon.py
    script_status 'Battery warning' i3_battery-popup.sh
    script_status 'Notification log' i3_notify_logger.sh
}

case ${1:-show} in
    status) collect_status ;;
    health) collect_health ;;
    show-health)
        collect_health |
            rofi -dmenu -no-custom -i -p 'Session health' \
                -mesg 'Running or stopped · A stopped optional component may be intentional · Enter or Escape to close' \
                -config "$ROFI_CONFIG" \
                -theme-str '#window { padding: 12% 12%; } #listview { lines: 14; columns: 1; }' \
                >/dev/null
        ;;
    show)
        # The rows are informational: Enter or Escape only closes the view.
        collect_status |
            rofi -dmenu -no-custom -i -p 'System status' \
                -mesg 'Current state · Enter or Escape to close' \
                -config "$ROFI_CONFIG" \
                -theme-str '#window { padding: 16% 12%; } #listview { lines: 12; columns: 1; }' \
                >/dev/null
        ;;
    *) printf 'Usage: %s {show|status|show-health|health}\n' "$0" >&2; exit 2 ;;
esac
