#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Keep the screen awake while a fullscreen window is visible or audio plays
###########################################################

# Requirements:
#   i3-msg jq pactl xset

# Usage: i3_idle_inhibitor.sh
#
# Desktop environments skip the idle lock while you watch a video or sit in a call
# (apps ask them to). Bare i3 has nothing that answers those requests, so this
# watcher resets the X screen saver timer (`xset s reset`, as if you had moved the
# mouse) every CHECK_SECONDS while either is true:
#   - a fullscreen window is on a visible workspace
#   - an audio stream is playing (not paused). Music playing counts too.
# It does nothing while the screen is locked (i3lock running), so the screen still
# turns off after you lock it. Caffeine (screen saver off) is unaffected.
# CHECK_SECONDS must stay well below the screen saver timeout set in
# i3_toolkit_operator.sh disable_caffeine (590 s).

source "$(dirname "$(readlink -f "$0")")/i3_single_instance.sh"

CHECK_SECONDS=30

fullscreen_visible () {
    local visible
    visible=$(i3-msg -t get_workspaces | jq -c '[.[] | select(.visible) | .name]') || return 1
    # Look below each visible workspace (workspace nodes themselves report a fullscreen_mode)
    i3-msg -t get_tree | jq -e --argjson visible "$visible" '
        [.. | objects | select(.type? == "workspace" and (.name as $n | $visible | index($n)) != null)
            | (.nodes[], .floating_nodes[]) | .. | objects | select((.fullscreen_mode? // 0) > 0)]
        | length > 0' > /dev/null
}

audio_playing () {
    pactl list sink-inputs 2> /dev/null | grep -q 'Corked: no'
}

while sleep "$CHECK_SECONDS"; do
    pgrep -u "$(id -u)" -x i3lock > /dev/null && continue
    if fullscreen_visible || audio_playing; then
        xset s reset
    fi
done
