#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Keep the screen awake while a fullscreen window is visible or a call runs
###########################################################

# Requirements:
#   i3-msg jq pactl xset

# Usage: i3_idle_inhibitor.sh
#
# Desktop environments skip the idle lock while you watch a video or sit in a call
# (apps ask them to). Bare i3 has nothing that answers those requests, so this
# watcher checks every CHECK_SECONDS for:
#   - a fullscreen window on a visible workspace (videos, presentations, games)
#   - a microphone in use (calls, meetings, voice chat). Plain playback (music, or
#     an app that keeps an audio stream open) does not count, so it cannot stop
#     the lock forever.
# While either is true it resets the screen saver timer (`xset s reset`, as if you
# had moved the mouse) and turns DPMS off. `xset s reset` does not hold off DPMS,
# so without that the screen would turn off at the DPMS timeout with no lock.
# DPMS is turned back on as soon as neither is true.
#
# Leaves everything alone while the screen is locked (i3lock running), so the screen
# still turns off after you lock it, and while Caffeine is on (screen saver off).
# CHECK_SECONDS must stay well below the screen saver timeout set in
# i3_toolkit_operator.sh disable_caffeine (590 s).

source "$(dirname "$(readlink -f "$0")")/i3_single_instance.sh"

CHECK_SECONDS=30
# yes while DPMS is off because of this script (so only we turn it back on)
HOLDING_DPMS=no

fullscreen_visible () {
    local visible
    visible=$(i3-msg -t get_workspaces | jq -c '[.[] | select(.visible) | .name]') || return 1
    # Look below each visible workspace (workspace nodes themselves report a fullscreen_mode)
    i3-msg -t get_tree | jq -e --argjson visible "$visible" '
        [.. | objects | select(.type? == "workspace" and (.name as $n | $visible | index($n)) != null)
            | (.nodes[], .floating_nodes[]) | .. | objects | select((.fullscreen_mode? // 0) > 0)]
        | length > 0' > /dev/null
}

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

# Caffeine turns the screen saver off (timeout 0); DPMS is then not ours to manage
caffeine_on () {
    xset q 2> /dev/null | grep -Eq '^\s*timeout:\s+0\b'
}

dpms_enabled () {
    xset q 2> /dev/null | grep -q 'DPMS is Enabled'
}

hold_dpms () {
    [[ $HOLDING_DPMS == yes ]] && return 0
    dpms_enabled || return 0
    xset -dpms && HOLDING_DPMS=yes
}

release_dpms () {
    [[ $HOLDING_DPMS == yes ]] || return 0
    HOLDING_DPMS=no
    xset +dpms
}

trap 'release_dpms; exit 0' TERM INT

# A copy stopped without cleaning up (e.g. killed) may have left DPMS off
if ! caffeine_on && ! dpms_enabled; then
    xset +dpms
fi

while sleep "$CHECK_SECONDS"; do
    if caffeine_on; then
        # Caffeine owns DPMS now; do not turn it back on later
        HOLDING_DPMS=no
        continue
    fi
    if pgrep -u "$(id -u)" -x i3lock > /dev/null; then
        release_dpms
        continue
    fi
    if fullscreen_visible || in_call; then
        xset s reset
        hold_dpms
    else
        release_dpms
    fi
done
