#!/usr/bin/env bash
# ~/.config/sway/script/sway_idle_inhibitor.sh
# Ported from i3_idle_inhibitor.sh for sway.
# Replaced X11 tools:
#   - fullscreen check + xset s reset -> not needed: sway_window.config sets
#       `inhibit_idle fullscreen` on every window, which swayidle respects.
#   - audio check + xset s reset -> swayidle cannot be reset from outside, so while
#       audio plays one open window gets `inhibit_idle open` (idle is inhibited as
#       long as that window exists); it is set back to `inhibit_idle fullscreen`
#       when the audio stops. If that window closes, another one is picked.
# Requirements: swaymsg jq pactl
# Music playing counts too. Nothing is inhibited while swaylock runs, so the screen
# still turns off after you lock it.

I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"
source "$I3_SCRIPT/i3_single_instance.sh"

CHECK_SECONDS=30
INHIBITED_CON=

audio_playing () {
    pactl list sink-inputs 2> /dev/null | grep -q 'Corked: no'
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
    if pgrep -u "$(id -u)" -x swaylock > /dev/null || ! audio_playing; then
        release
        continue
    fi
    [[ -n $INHIBITED_CON ]] && con_exists "$INHIBITED_CON" && continue
    INHIBITED_CON=$(any_window)
    [[ -n $INHIBITED_CON ]] && swaymsg "[con_id=$INHIBITED_CON] inhibit_idle open" > /dev/null
done
