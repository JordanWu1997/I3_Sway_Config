#!/usr/bin/env bash
# ~/.config/i3/script/i3_single_instance.sh
#
# Source this at the top of a long-running i3 helper script (battery warning,
# notification logger, memory notifier, ...) to make it replace any copy that is
# already running:
#
#   source "$(dirname "$(readlink -f "$0")")/i3_single_instance.sh"
#
# Why: these loops do not need X, and Ubuntu's logind keeps user processes alive
# after logout (KillUserProcesses=no). Without this, every re-login adds a copy.
#
# Only processes that run this script (bash|sh <path>/<script>) are matched, so an
# editor that has the file open is never touched. Their children (sleep,
# dbus-monitor, ...) are stopped too.

i3_replace_running_copy() {
    local name pid ppid
    name=$(basename "$0")
    local pattern="^([^ ]*/)?(ba)?sh ([^ ]*/)?${name//./\\.}( |$)"
    local -a old=()
    for pid in $(pgrep -u "$(id -u)" -f -- "$pattern"); do
        [[ $pid == "$$" ]] && continue
        # Skip our own subshells (e.g. the one running this pgrep)
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null) || continue
        [[ ${ppid//[[:space:]]/} == "$$" ]] && continue
        old+=("$pid")
    done
    ((${#old[@]})) || return 0
    for pid in "${old[@]}"; do
        pkill -TERM -P "$pid" 2>/dev/null
    done
    kill -TERM "${old[@]}" 2>/dev/null
}

i3_replace_running_copy
