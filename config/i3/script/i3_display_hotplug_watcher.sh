#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Re-apply the display layout when a monitor is plugged in or removed
###########################################################

# Requirements:
#   xev (x11-utils) xrandr

# Usage: i3_display_hotplug_watcher.sh [enable|disable]
#   The argument is passed on to `i3_display_operator.sh auto` (reload conky or not).

# How it works: xev reports RandR events from the X server. One plug or unplug
# produces a burst of them, and so does every xrandr layout change (including the
# ones i3_display_operator.sh makes). So after a burst has settled, only a change
# in WHICH outputs are connected runs `auto`. Manual layouts (display mode) are
# kept until the next plug or unplug.

source "$(dirname "$(readlink -f "$0")")/i3_single_instance.sh"

DISPLAY_OPERATOR="$(dirname "$(readlink -f "$0")")/i3_display_operator.sh"
CONKY_STARTUP=${1:-disable}
SETTLE_SECONDS=2

# --current reads the server's state without re-probing the outputs: probing is
# slow and can itself emit RandR events
connected_outputs() {
    xrandr --current | awk '$2 == "connected" {print $1}'
}

last=$(connected_outputs)
stdbuf -oL xev -root -event randr | while IFS= read -r line; do
    [[ $line == RR* ]] || continue
    # Wait until no event has arrived for SETTLE_SECONDS
    while IFS= read -r -t "$SETTLE_SECONDS" line; do :; done
    current=$(connected_outputs)
    [[ $current == "$last" ]] && continue
    last=$current
    "$DISPLAY_OPERATOR" auto "$CONKY_STARTUP"
done
