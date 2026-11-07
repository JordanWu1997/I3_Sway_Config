#!/usr/bin/env bash
# ~/.config/sway/script/sway_system_status.sh
# Ported from i3_system_status.sh for sway.
# Replaced X11 checks:
#   - xset q (caffeine)              -> ${XDG_RUNTIME_DIR}/sway_caffeine (sway_toolkit_operator.sh)
#   - xss-lock                       -> swayidle (sway_idle_operator.sh)
#   - picom (compositor mode)        -> built into sway; reports `opacity` rules in the config
#   - unclutter                      -> `seat * hide_cursor <ms>` in the sway config
#   - setxkbmap -query (Caps Lock)   -> sway_keyboard_operator.sh state / xkb_options in the
#                                       sway config; layout from `swaymsg -t get_inputs`
#   - i3-msg -t get_bar_config       -> swaymsg -t get_bar_config
#   - parcellite                     -> cliphist watchers (wl-paste --watch cliphist store)
#   - DISPLAY (other X sessions)     -> WAYLAND_DISPLAY, then DISPLAY
# Component scripts: sway_<name> in $SWAY_SCRIPT is preferred, else i3_<name> in $I3_SCRIPT.

# One read-only System view: device state, session toggles and background
# components. Rows that may surprise the user are repeated under "Needs attention".
SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"
# Same window layout as the application menu (Super+d)
ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
SWAY_CONFIG="$HOME/.config/sway/config"
SWAY_CONFIG_DIR="$HOME/.config/sway/config.d"
CAFFEINE_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway_caffeine"
KEYBOARD_STATE="${XDG_RUNTIME_DIR:-/tmp}/sway_keyboard_state"
ICON="$HOME/.config/i3/share/64x64/list.png"

# Path of a helper script: sway_<name> if ported, else i3_<name>
script_file() {
    if [[ -e $SWAY_SCRIPT/sway_$1 ]]; then
        printf '%s\n' "$SWAY_SCRIPT/sway_$1"
    else
        printf '%s\n' "$I3_SCRIPT/i3_$1"
    fi
}

component_status() {
    local script fallback=$2
    script=$(script_file "$1")
    if [[ -x $script ]]; then
        "$script" status || printf '%s | unavailable\n' "$fallback"
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
    component_status battery_notification.sh Battery
    component_status network_operator.sh Network
    component_status bluetooth_operator.sh Bluetooth
    component_status RF_device_operator.sh 'Radio blocks'
    component_status pulseaudio_notification.sh Audio
    notification_status
}

# ------------------------------------------------------------------
# Session toggles: states that change behaviour without a visible cue
# ------------------------------------------------------------------

running() {
    pgrep -u "$(id -u)" -x "$1" >/dev/null 2>&1
}

caffeine_on() {
    [[ $(cat "$CAFFEINE_FILE" 2>/dev/null) == on ]]
}

# swayidle started by sway_idle_operator.sh (the one-shot of Super+Shift+l is not counted)
idle_daemon_running() {
    pgrep -u "$(id -u)" -f '^swayidle .*sway_lock_operator\.sh' >/dev/null 2>&1
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

# All sway config files (main config first)
sway_config_files() {
    printf '%s\n' "$SWAY_CONFIG" "$SWAY_CONFIG_DIR"/*.config
}

compositor_mode() {
    # sway composites itself (no picom); report whether opacity rules are configured
    if sway_config_files | xargs grep -hEq '^[^#]*\bopacity\b' 2>/dev/null; then
        printf 'built-in (opacity rules)\n'
    else
        printf 'built-in\n'
    fi
}

config_value() {
    # Print the value of a sway option as written in the config file
    awk -v key="$1" '$1 == key {print $2; exit}' "$SWAY_CONFIG_DIR/$2" 2>/dev/null
}

bar_mode() {
    local mode
    mode=$(swaymsg -t get_bar_config bar_status -r 2>/dev/null | jq -r '.mode // "unknown"' 2>/dev/null)
    printf '%s\n' "${mode:-unknown}"
}

# Last `seat ... hide_cursor <ms>` line in the config (runtime changes are not queryable)
cursor_hide_ms() {
    sway_config_files | xargs awk '$1 == "seat" && $3 == "hide_cursor" && $4 ~ /^[0-9]+$/ {v = $4} END {print v}' 2>/dev/null
}

# Caps Lock remap: sway_keyboard_operator.sh state, else xkb_options in the config
caps_mode() {
    local CAPS='' opts
    if [[ -r $KEYBOARD_STATE ]]; then
        CAPS=$(sed -n 's/^CAPS=//p' "$KEYBOARD_STATE" | head -n 1)
    fi
    if [[ -z $CAPS ]]; then
        opts=$(sway_config_files | xargs grep -hE '^[^#]*xkb_options' 2>/dev/null | tail -n 1)
        case $opts in
            *ctrl:nocaps*) CAPS=nocaps ;;
            *ctrl:swapcaps*) CAPS=swapcaps ;;
        esac
    fi
    printf '%s\n' "${CAPS:-none}"
}

keyboard_layout() {
    swaymsg -t get_inputs -r 2>/dev/null |
        jq -r 'first(.[] | select(.type == "keyboard" and .xkb_active_layout_name != null) | .xkb_active_layout_name) // empty' 2>/dev/null
}

collect_session() {
    local lock focus
    if caffeine_on; then
        printf 'Caffeine | on (screen never blanks)\n'
    else
        printf 'Caffeine | off\n'
    fi
    if ! idle_daemon_running; then
        lock='off (swayidle stopped)'
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
    focus=$(config_value focus_follows_mouse sway_window.config)
    printf 'Focus follows mouse | %s\n' "${focus:-unknown}"
    if grep -q 'Mod4+h focus left, exec' "$SWAY_CONFIG_DIR/sway_bindkey.config" 2>/dev/null; then
        printf 'Mouse follows focus | yes\n'
    else
        printf 'Mouse follows focus | no\n'
    fi
    local hide layout
    hide=$(cursor_hide_ms)
    if [[ -n $hide && $hide != 0 ]]; then
        printf 'Cursor auto-hide | on (after %s ms)\n' "$hide"
    else
        printf 'Cursor auto-hide | off\n'
    fi
    case $(caps_mode) in
        nocaps) printf 'Caps Lock | acts as Ctrl\n' ;;
        swapcaps) printf 'Caps Lock | swapped with Ctrl\n' ;;
        *) printf 'Caps Lock | normal\n' ;;
    esac
    layout=$(keyboard_layout)
    [[ -n $layout ]] && printf 'Keyboard layout | %s\n' "$layout"
    command -v ibus >/dev/null 2>&1 &&
        printf 'Input method | %s\n' "$(ibus engine 2>/dev/null || printf 'unavailable')"
}

# ------------------------------------------------------------------
# Background components
# ------------------------------------------------------------------

# Count instances among the given PIDs. A forked child of a matching process
# (bash subshells and pipelines keep the parent's command line) is part of the
# same instance, so only PIDs whose parent is not also in the list are counted.
# Display a process was started with: "wayland:<WAYLAND_DISPLAY>" or "x11:<DISPLAY>";
# empty when it has none or is unreadable
process_display() {
    local env w d
    env=$(tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null) || return 0
    w=$(sed -n 's/^WAYLAND_DISPLAY=//p' <<< "$env" | head -n 1)
    d=$(sed -n 's/^DISPLAY=//p' <<< "$env" | head -n 1)
    if [[ -n $w ]]; then
        printf 'wayland:%s\n' "$w"
    elif [[ -n $d ]]; then
        printf 'x11:%s\n' "$d"
    fi
}

own_display() {
    if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
        printf 'wayland:%s\n' "$WAYLAND_DISPLAY"
    elif [[ -n ${DISPLAY:-} ]]; then
        printf 'x11:%s\n' "$DISPLAY"
    fi
}

# Print "<here> <elsewhere>": top-level instances on this display, and on
# other displays. Another login that was never logged out (e.g. a GNOME
# session on :2) runs its own tray apps; those are not duplicates here.
# Processes without a DISPLAY count as here.
count_instances() {
    local -A pidset=()
    local pid ppid display here=0 elsewhere=0 own
    own=$(own_display)
    for pid in "$@"; do pidset[$pid]=1; done
    for pid in "$@"; do
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null) || continue
        ppid=${ppid//[[:space:]]/}
        [[ -z ${pidset[$ppid]:-} ]] || continue
        display=$(process_display "$pid")
        if [[ -n $display && -n $own && $display != "$own" ]]; then
            elsewhere=$((elsewhere + 1))
        else
            here=$((here + 1))
        fi
    done
    printf '%s %s\n' "$here" "$elsewhere"
}

instance_status() {
    local label=$1 here elsewhere suffix=
    read -r here elsewhere <<< "$2"
    (( elsewhere > 0 )) && suffix=" (+${elsewhere} in other sessions)"
    if (( here > 1 )); then
        printf '%s | running ×%s (duplicate)%s\n' "$label" "$here" "$suffix"
    elif (( here == 1 )); then
        printf '%s | running%s\n' "$label" "$suffix"
    else
        printf '%s | stopped%s\n' "$label" "$suffix"
    fi
}

# Other graphical logins of this user that are still open. Their programs keep
# running (and keep memory) until the session is logged out or terminated.
other_sessions_status() {
    local id class type state display list=()
    command -v loginctl >/dev/null || return 0
    while read -r id _; do
        [[ -n $id && $id != "${XDG_SESSION_ID:-}" ]] || continue
        { read -r class; read -r type; read -r state; read -r display; } < <(
            loginctl show-session "$id" -p Class -p Type -p State -p Display --value 2>/dev/null)
        [[ $class == user && $type =~ ^(x11|wayland)$ ]] || continue
        list+=("$id ($type${display:+ $display}, $state)")
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$USER" '$3 == u')
    if (( ${#list[@]} )); then
        local IFS=,
        printf 'Other logins | %s · end with: loginctl terminate-session ID\n' "${list[*]}"
    else
        printf 'Other logins | none\n'
    fi
}

process_status() {
    local label=$1 name=$2
    local -a pids
    mapfile -t pids < <(pgrep -u "$(id -u)" -x "$name" 2>/dev/null)
    instance_status "$label" "$(count_instances "${pids[@]}")"
}

script_status() {
    local label=$1 script target pid arg resolved
    local -a argv pids=()
    script=$(basename -- "$(script_file "$2")")
    target=$(readlink -f -- "$(script_file "$2")") || {
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
                pids+=("$pid")
                break
            fi
        done
    done < <(pgrep -u "$(id -u)" -f "$script" || true)
    instance_status "$label" "$(count_instances "${pids[@]}")"
}

# cliphist runs as one wl-paste watcher per MIME type (text + image): count types
clipboard_status() {
    local -a pids text=() image=() other=()
    local pid cmd
    mapfile -t pids < <(pgrep -u "$(id -u)" -f '^wl-paste .*--watch cliphist' 2>/dev/null)
    for pid in "${pids[@]}"; do
        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        case $cmd in
            *'--type text'*|*'-t text'*) text+=("$pid") ;;
            *'--type image'*|*'-t image'*) image+=("$pid") ;;
            *) other+=("$pid") ;;
        esac
    done
    local here n=0 dup=0 kind types=()
    local -a group
    for kind in text image other; do
        case $kind in
            text) group=("${text[@]}") ;;
            image) group=("${image[@]}") ;;
            other) group=("${other[@]}") ;;
        esac
        (( ${#group[@]} )) || continue
        read -r here _ <<< "$(count_instances "${group[@]}")"
        if (( here > 0 )); then
            types+=("$kind")
            n=$((n + 1))
        fi
        (( here > 1 )) && dup=1
    done
    if (( n == 0 )); then
        printf 'Clipboard manager | stopped\n'
    elif (( dup )); then
        printf 'Clipboard manager | running (cliphist: %s) (duplicate)\n' "${types[*]}"
    else
        printf 'Clipboard manager | running (cliphist: %s)\n' "${types[*]}"
    fi
}

idle_status() {
    local -a pids
    mapfile -t pids < <(pgrep -u "$(id -u)" -f '^swayidle .*sway_lock_operator\.sh' 2>/dev/null)
    instance_status 'Screen lock helper' "$(count_instances "${pids[@]}")"
}

collect_health() {
    other_sessions_status
    idle_status
    process_status 'Notification daemon' dunst
    clipboard_status
    process_status 'Network tray' nm-applet
    process_status 'Bluetooth tray' blueman-applet
    # comm names are cut to 15 characters: polkit-gnome-authentication-agent-1
    process_status 'Auth agent (polkit)' polkit-gnome-au
    process_status 'Input method daemon' ibus-daemon
    process_status 'Autotiling process' autotiling
    process_status 'Focus flash process' flashfocus
    script_status 'Window automark' automark_daemon.py
    script_status 'Battery warning' battery-popup.sh
    script_status 'Notification log' notify_logger.sh
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
        $1 == "Screen lock helper" && $2 ~ /^stopped/ { print; next }
        $1 == "Notification daemon" && $2 ~ /^stopped/ { print; next }
        $1 == "Other logins" && $2 != "none" { print; next }
        $2 ~ /\(duplicate\)/ { print; next }
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
    cache=$(mktemp -d "${TMPDIR:-/tmp}/sway-system-status.XXXXXX") || return 1
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
    body+=$'\n'"Focus follows mouse: $(config_value focus_follows_mouse sway_window.config)"
    [[ $(caps_mode) == nocaps ]] && body+=$'\nCaps Lock acts as Ctrl'
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
