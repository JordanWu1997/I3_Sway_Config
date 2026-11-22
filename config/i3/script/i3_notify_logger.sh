#!/usr/bin/env bash

# https://gitlab.com/dwt1/dotfiles/-/blob/master/.local/bin/notify-log

logfile=${1:-$HOME/.config/dunst/log.txt}

declare -a MSGBUF=()
STATE=off
MSGTIME=

printbuf() {
  [[ $STATE == on && ${#MSGBUF[@]} -gt 0 ]] || return
  JOINED=$(printf '%s' "${MSGBUF[@]}")
  JOINED=${JOINED%,}
  # v2 keeps empty Notify string arguments, so the history viewer can reliably
  # distinguish app name, icon, summary, and body. Older records stay readable.
  printf "%s\n%s\n" "--- ${MSGTIME} v2 ---" "${JOINED}"
}

procmsg() {
  if [[ "${1}" =~ member=Notify$ ]]; then
    printbuf
    STATE=on
    MSGTIME=$(date '+%Y-%m-%d %H:%M:%S')
    MSGBUF=()
  elif [[ -z $1 || $1 == method\ call* || $1 == signal* ]]; then
    printbuf
    STATE=off
  else
   if [[ "${STATE}" == "on" ]]; then
      if [[ "${1}" =~ ^string ]]; then
        case "${1}" in
          "string \"urgency\"") ;;
          "string \"sender-pid\"") ;;
          *)
            MSGBUF+=("${1},")
          ;;
        esac
      fi
    fi
  fi
}

# Replace a copy left running from an earlier login (see i3_single_instance.sh)
source "$(dirname "$(readlink -f "$0")")/i3_single_instance.sh"

dbus-monitor "interface='org.freedesktop.Notifications'" | \
    while IFS= read -r line; do
      procmsg "$line" >> "$logfile"
    done
