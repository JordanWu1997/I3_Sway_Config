#!/usr/bin/env bash
# ~/.config/i3/script/i3_session_env.sh
#
# Source this in scripts that run outside i3 (cron jobs, ...) and need the i3
# session, then call import_i3_session_env:
#
#   source "$(dirname "$(readlink -f "$0")")/i3_session_env.sh"
#   import_i3_session_env || exit 1
#
# cron starts jobs with an almost empty environment: no DISPLAY, XAUTHORITY or D-Bus
# address. These are copied from the running i3 process, so the display number
# (:0, :1 ...), the Xauthority path (~/.Xauthority, /run/user/<uid>/gdm/Xauthority ...)
# and the session bus always match the current i3 session, on every machine.
#   DISPLAY, XAUTHORITY:      i3-msg finds the i3 IPC socket through the X session
#   DBUS_SESSION_BUS_ADDRESS: notify-send reaches the dunst that i3 started, which
#                             draws on i3's display

import_i3_session_env() {
    local pid entry
    pid=$(pgrep -n -u "$(id -u)" -x i3) || {
        echo 'i3 is not running for this user' >&2
        return 1
    }
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
}
