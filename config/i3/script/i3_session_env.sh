#!/usr/bin/env bash
# ~/.config/i3/script/i3_session_env.sh
#
# Source this in scripts that run outside i3 (cron jobs, ...) and need the i3
# session(s):
#
#   source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"
#
#   # run a command (or shell function) once in every i3 session of this user
#   for_each_i3_session my_function arg ... || exit 1
#
#   # or: only the newest i3 session, imported into the current shell
#   import_i3_session_env || exit 1
#
# cron starts jobs with an almost empty environment: no DISPLAY, XAUTHORITY or D-Bus
# address. These are copied from the running i3 process(es), so the display number
# (:0, :1 ...), the Xauthority path (~/.Xauthority, /run/user/<uid>/gdm/Xauthority ...)
# and the session bus always match each i3 session, on every machine.
#   DISPLAY, XAUTHORITY:      i3-msg finds the i3 IPC socket through the X session
#   DBUS_SESSION_BUS_ADDRESS: notify-send reaches the dunst that i3 started, which
#                             draws on i3's display

# PIDs of this user's running i3 processes, one per line (one per i3 session)
i3_session_pids() {
    pgrep -u "$(id -u)" -x i3
}

# import_i3_session_env [PID]: export the session environment of the i3 process PID
# (default: the newest i3 of this user) into the current shell
import_i3_session_env() {
    local pid=${1:-} entry
    if [[ -z $pid ]]; then
        pid=$(pgrep -n -u "$(id -u)" -x i3) || {
            echo 'i3 is not running for this user' >&2
            return 1
        }
    fi
    [[ -r /proc/$pid/environ ]] || {
        echo "Cannot read the environment of i3 (PID $pid)" >&2
        return 1
    }
    # Values from another session must not leak into this one. I3SOCK matters most:
    # i3-msg prefers it over DISPLAY, so a script started from a terminal of one i3
    # session would otherwise send every i3-msg to that session's i3.
    unset DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR I3SOCK
    while IFS= read -r -d '' entry; do
        case ${entry%%=*} in
            DISPLAY|XAUTHORITY|DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR) export "$entry" ;;
        esac
    done < "/proc/$pid/environ"
    [[ -n ${DISPLAY:-} ]] || {
        echo "i3 (PID $pid) has no DISPLAY" >&2
        return 1
    }
    # notify-send finds the session bus through it when no D-Bus address was found
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
    # Pin i3-msg to exactly this i3: its default IPC socket carries its PID; otherwise
    # (ipc-socket set in the config) ask the X display it runs on
    local sock="$XDG_RUNTIME_DIR/i3/ipc-socket.$pid"
    [[ -S $sock ]] || sock=$(i3 --get-socketpath 2>/dev/null)
    [[ -S $sock ]] || {
        echo "Cannot find the IPC socket of i3 (PID $pid)" >&2
        return 1
    }
    export I3SOCK=$sock
    export I3_SESSION_PID=$pid
}

# for_each_i3_session [--unique-dbus] COMMAND [ARGS...]
#
# Runs COMMAND once for every i3 session of this user, each time in a subshell with
# that session's environment imported (and I3_SESSION_PID set). COMMAND may be a shell
# function of the calling script.
#
# --unique-dbus: run only once per D-Bus session bus. Sessions of one user usually share
# the systemd user bus (/run/user/<uid>/bus) and so one notification daemon; without
# this a notification would pop up there once per i3 session.
#
# Returns 1 when i3 is not running or COMMAND failed in any session (the other
# sessions are still handled).
for_each_i3_session() {
    local unique_dbus=0 pids pid bus status=0
    local -A seen_bus=()
    if [[ ${1:-} == --unique-dbus ]]; then
        unique_dbus=1
        shift
    fi
    (( $# )) || { echo 'for_each_i3_session: no command given' >&2; return 2; }

    pids=$(i3_session_pids) || {
        echo 'i3 is not running for this user' >&2
        return 1
    }
    for pid in $pids; do
        if (( unique_dbus )); then
            bus=$(import_i3_session_env "$pid" &&
                printf '%s' "${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}") ||
                { status=1; continue; }
            [[ -n ${seen_bus[$bus]:-} ]] && continue
            seen_bus[$bus]=1
        fi
        ( import_i3_session_env "$pid" && "$@" ) || status=1
    done
    return "$status"
}
