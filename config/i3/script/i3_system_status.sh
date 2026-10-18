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

case ${1:-show} in
    status) collect_status ;;
    show)
        # The rows are informational: Enter or Escape only closes the view.
        collect_status |
            rofi -dmenu -no-custom -i -p 'System status' \
                -mesg 'Current state · Enter or Escape to close' \
                -config "$ROFI_CONFIG" \
                -theme-str '#window { padding: 16% 12%; } #listview { lines: 12; columns: 1; }' \
                >/dev/null
        ;;
    *) printf 'Usage: %s {show|status}\n' "$0" >&2; exit 2 ;;
esac
