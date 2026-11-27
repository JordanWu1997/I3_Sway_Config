#!/usr/bin/env bash
# ~/.config/sway/script/sway_idle_inhibitor.sh
# Ported from i3_idle_inhibitor.sh for sway.
# Replaced X11 tools:
#   - fullscreen check + xset s reset -> not needed: sway_window.config sets
#       `inhibit_idle fullscreen` on every window, which swayidle respects.
#   - call check (microphone in use) + xset s reset -> swayidle cannot be reset
#       from outside, so during a call one open window gets `inhibit_idle open`
#       (idle is inhibited as long as that window exists); it is set back to
#       `inhibit_idle fullscreen` when the call ends. If that window closes,
#       another one is picked. swayidle also handles screen off, so DPMS needs
#       no extra care here (unlike i3).
# Requirements: swaymsg jq pactl
# Plain playback (music, or an app that keeps an audio stream open) does not count.
# Nothing is inhibited while swaylock runs, so the screen still turns off after
# you lock it.

I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"
source "$I3_SCRIPT/i3_single_instance.sh"

CHECK_SECONDS=30
INHIBITED_CON=

# A running (not paused) recording from a real input. ".monitor" sources only
# listen to what is playing (e.g. cava), so they do not count.
in_call () {
    local monitors
    monitors=$(pactl list short sources 2> /dev/null | awk '$2 ~ /\.monitor$/ {print $1}')
    pactl list source-outputs 2> /dev/null | awk -v monitors=" $(echo $monitors) " '
        /^Source Output #/   { source = "" }
        /^[ \t]+Source: /    { source = $2 }
        /^[ \t]+Corked: no/ && index(monitors, " " source " ") == 0 { found = 1 }
        END { exit !found }'
}

con_exists () {
    swaymsg -t get_tree | jq -e --argjson id "$1" 'any(.. | objects; .id? == $id)' > /dev/null
}

# Any application window (tiling or floating)
any_window () {
    swaymsg -t get_tree | jq -r 'first(.. | objects
        | select((.type? == "con" or .type? == "floating_con") and .pid? != null) | .id) // empty'
}

release () {
    [[ -n $INHIBITED_CON ]] || return 0
    swaymsg "[con_id=$INHIBITED_CON] inhibit_idle fullscreen" > /dev/null 2>&1
    INHIBITED_CON=
}
trap 'release; exit 0' TERM INT

while sleep "$CHECK_SECONDS"; do
    if pgrep -u "$(id -u)" -x swaylock > /dev/null || ! in_call; then
        release
        continue
    fi
    [[ -n $INHIBITED_CON ]] && con_exists "$INHIBITED_CON" && continue
    INHIBITED_CON=$(any_window)
    [[ -n $INHIBITED_CON ]] && swaymsg "[con_id=$INHIBITED_CON] inhibit_idle open" > /dev/null
done
