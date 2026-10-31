#!/usr/bin/env bash

# One read-only System view: device state, session toggles and background
# components. Rows that may surprise the user are repeated under "Needs attention".
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Same window layout as the application menu (Super+d)
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
I3_CONFIG_DIR="$HOME/.config/i3/config.d"
ICON="$HOME/.config/i3/share/64x64/list.png"

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
        true) printf 'Notifications | paused (do not disturb)\n' ;;
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

# ------------------------------------------------------------------
# Session toggles: states that change behaviour without a visible cue
# ------------------------------------------------------------------

running() {
    pgrep -u "$(id -u)" -x "$1" >/dev/null 2>&1
}

caffeine_on() {
    local xset_query
    xset_query=$(xset q 2>/dev/null) || return 1
    grep -q 'DPMS is Disabled' <<< "$xset_query" &&
        grep -Eq '^\s*timeout:\s+0\b' <<< "$xset_query"
}

autotiling_mode() {
    local cmdline
    cmdline=$(pgrep -u "$(id -u)" -a -x autotiling 2>/dev/null | head -n 1)
    if [[ -z $cmdline ]]; then
        printf 'off\n'
    elif [[ $cmdline == *--limit\ 2* ]]; then
        printf 'master-stack\n'
    else
        printf 'dwindling\n'
    fi
}

compositor_mode() {
    local cmdline
    cmdline=$(pgrep -u "$(id -u)" -a -x picom 2>/dev/null | head -n 1)
    case $cmdline in
        '') printf 'off\n' ;;
        *transparency*) printf 'transparency\n' ;;
        *blur*) printf 'blur\n' ;;
        *) printf 'default\n' ;;
    esac
}

config_value() {
    # Print the value of an i3 option as written in the config file
    awk -v key="$1" '$1 == key {print $2; exit}' "$I3_CONFIG_DIR/$2" 2>/dev/null
}

bar_mode() {
    i3-msg -t get_bar_config bar_status 2>/dev/null | jq -r '.mode // "unknown"' 2>/dev/null ||
        printf 'unknown\n'
}

collect_session() {
    local lock focus
    if caffeine_on; then
        printf 'Caffeine | on (screen never blanks)\n'
    else
        printf 'Caffeine | off\n'
    fi
    if ! running xss-lock; then
        lock='off (xss-lock stopped)'
    elif caffeine_on; then
        lock='off while caffeine is on'
    else
        lock=on
    fi
    printf 'Auto-lock on idle | %s\n' "$lock"
    printf 'Autotiling | %s\n' "$(autotiling_mode)"
    printf 'Compositor | %s\n' "$(compositor_mode)"
    running flashfocus && printf 'Focus flash | on\n' || printf 'Focus flash | off\n'
    printf 'Status bar | %s\n' "$(bar_mode)"
    focus=$(config_value focus_follows_mouse i3_window.config)
    printf 'Focus follows mouse | %s\n' "${focus:-unknown}"
    if grep -q 'Mod4+h focus left, exec' "$I3_CONFIG_DIR/i3_bindkey.config" 2>/dev/null; then
        printf 'Mouse follows focus | yes\n'
    else
        printf 'Mouse follows focus | no\n'
    fi
    running unclutter && printf 'Cursor auto-hide | on\n' || printf 'Cursor auto-hide | off\n'
    case $(setxkbmap -query 2>/dev/null | awk '$1 == "options:" {print $2}') in
        *ctrl:nocaps*) printf 'Caps Lock | acts as Ctrl\n' ;;
        *) printf 'Caps Lock | normal\n' ;;
    esac
    command -v ibus >/dev/null 2>&1 &&
        printf 'Input method | %s\n' "$(ibus engine 2>/dev/null || printf 'unavailable')"
}

# ------------------------------------------------------------------
# Background components
# ------------------------------------------------------------------

process_status() {
    local label=$1 name=$2
    if running "$name"; then
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
    process_status 'Notification daemon' dunst
    process_status 'Clipboard manager' parcellite
    process_status 'Network tray' nm-applet
    process_status 'Bluetooth tray' blueman-applet
    process_status 'Input method daemon' ibus-daemon
    process_status 'Compositor process' picom
    process_status 'Autotiling process' autotiling
    script_status 'Window automark' i3_automark_daemon.py
    script_status 'Battery warning' i3_battery-popup.sh
    script_status 'Notification log' i3_notify_logger.sh
}

# ------------------------------------------------------------------
# Merged view
# ------------------------------------------------------------------

needs_attention() {
    # Read "Label | value" rows; print the ones a user would want to know about
    awk -F' \\| ' '
        $1 == "Caffeine" && $2 ~ /^on/ { print; next }
        $1 == "Auto-lock on idle" && $2 ~ /^off/ { print; next }
        $1 == "Notifications" && $2 ~ /paused|unavailable/ { print; next }
        $1 == "Audio" && $2 ~ /output (0%|[^·]*\(muted\))/ { print; next }
        $1 == "Screen lock helper" && $2 == "stopped" { print; next }
        $1 == "Notification daemon" && $2 == "stopped" { print; next }
        $1 == "Battery" && $2 ~ /Discharging/ && match($2, /[0-9]+%/) &&
            substr($2, RSTART, RLENGTH - 1) + 0 <= 20 { print; next }
    '
}

collect_all() {
    local state session health attention
    state=$(collect_status)
    session=$(collect_session)
    health=$(collect_health)
    attention=$(printf '%s\n%s\n%s\n' "$state" "$session" "$health" | needs_attention)
    if [[ -n $attention ]]; then
        printf '━━ Needs attention ━━\n%s\n' "$(sed 's/^/⚠ /' <<< "$attention")"
    fi
    printf '━━ Devices ━━\n%s\n' "$state"
    printf '━━ Session toggles ━━\n%s\n' "$session"
    printf '━━ Background components ━━\n%s\n' "$health"
}

show_all() {
    local cache self status=0
    # Snapshot every section once; the three rofi tabs read the same snapshot
    cache=$(mktemp -d "${TMPDIR:-/tmp}/i3-system-status.XXXXXX") || return 1
    collect_status > "$cache/devices"
    collect_session > "$cache/session"
    collect_health > "$cache/health"
    cat "$cache/devices" "$cache/session" "$cache/health" | needs_attention > "$cache/attention"
    self=$(readlink -f -- "${BASH_SOURCE[0]}")
    # The rows are informational: Enter or Escape only closes the view.
    STATUS_CACHE=$cache rofi -show Devices -no-custom -i \
        -modi "Devices:$self tab devices,Session:$self tab session,Background:$self tab health" \
        -config "$ROFI_CONFIG" \
        -theme-str '#mainbox { children: [inputbar, mode-switcher, message, listview]; }
                    #listview { columns: 1; }' || status=$?
    rm -rf -- "$cache"
    return "$status"
}

show_tab() {
    local section=$1 attention row count tabs
    # rofi calls the tab again after Enter or a custom entry; printing nothing closes it
    [[ ${ROFI_RETV:-0} == 0 ]] || exit 0
    [[ -r $STATUS_CACHE/$section ]] || { printf 'Status snapshot unavailable\n'; return; }
    attention=$(cat "$STATUS_CACHE/attention" 2>/dev/null)
    count=$(grep -c . <<< "$attention")
    if (( count > 0 )); then
        tabs=$(awk -F' \\| ' 'NR==FNR {want[$0]; next} $0 in want {print FILENAME}' \
            "$STATUS_CACHE/attention" "$STATUS_CACHE/devices" "$STATUS_CACHE/session" "$STATUS_CACHE/health" |
            sed 's|.*/||; s/^devices$/Devices/; s/^session$/Session/; s/^health$/Background/' | sort -u | paste -sd, - | sed 's/,/, /g')
        printf '\0message\x1f⚠ %s item(s) need attention in: %s · Ctrl+Tab / Shift+←→: switch tab · Esc: close\n' "$count" "$tabs"
    else
        printf '\0message\x1fAll clear · Ctrl+Tab / Shift+←→: switch tab · Esc: close\n'
    fi
    printf '\0no-custom\x1ftrue\n'
    while IFS= read -r row; do
        [[ -n $row ]] || continue
        if [[ -n $attention ]] && grep -Fxq -- "$row" <<< "$attention"; then
            printf '⚠ %s\n' "$row"
        else
            printf '%s\n' "$row"
        fi
    done < "$STATUS_CACHE/$section" | column -t -s '|' -o '│'
}

# ------------------------------------------------------------------
# Login summary: one notification instead of discovering states later
# ------------------------------------------------------------------

login_summary() {
    local volume mute body attention
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o -m1 '[0-9]*%' | head -n 1)
    mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
    body="Volume: ${volume:-unknown}$([[ $mute == yes ]] && printf ' (muted)')"
    if caffeine_on; then
        body+=$'\nCaffeine: ON · screen will not blank or auto-lock'
    else
        body+=$'\nCaffeine: off · screen blanks and locks when idle'
    fi
    body+=$'\n'"Autotiling: $(autotiling_mode) · Status bar: $(bar_mode)"
    body+=$'\n'"Focus follows mouse: $(config_value focus_follows_mouse i3_window.config)"
    [[ $(setxkbmap -query 2>/dev/null) == *ctrl:nocaps* ]] && body+=$'\nCaps Lock acts as Ctrl'
    attention=$( { collect_status; collect_session; collect_health; } | needs_attention | grep -v '^Caffeine' )
    [[ -n $attention ]] && body+=$'\n\n⚠ '"${attention//$'\n'/$'\n⚠ '}"
    body+=$'\n\nHelp: Super+Shift+/ · Full status: Ctrl+Alt+S, then s'
    notify-send -u normal -t 20000 "Session started" "$body" --icon="$ICON"
}

case ${1:-show} in
    status) collect_status ;;
    session) collect_session ;;
    health) collect_health ;;
    all) collect_all ;;
    login) login_summary ;;
    show|show-health) show_all ;;
    tab) show_tab "${2:-devices}" ;;
    *) printf 'Usage: %s {show|all|status|session|health|login}\n' "$0" >&2; exit 2 ;;
esac
