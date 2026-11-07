#!/usr/bin/env bash
# ~/.config/sway/script/sway_nightlight.sh
# Replacement for `redshift -m randr -P -O <K>` / `redshift -x` on sway.
# On Wayland (wlr-gamma-control) the compositor resets the gamma ramp as soon as the
# client that set it exits, so a one-shot call cannot work: keep exactly one gammastep
# process running for the chosen temperature.
#
# Usage: sway_nightlight.sh set <kelvin>   # e.g. 3500
#        sway_nightlight.sh off
#        sway_nightlight.sh status
ICON="$HOME/.config/i3/share/64x64/lightbulb_icon.png"

stop() { pkill -u "$USER" -x gammastep 2>/dev/null; pkill -u "$USER" -x wlsunset 2>/dev/null; true; }

case "$1" in
    set)
        TEMP="${2//[^0-9]/}"
        if [ -z "$TEMP" ] || [ "$TEMP" -lt 1000 ] || [ "$TEMP" -gt 25000 ]; then
            notify-send -u normal "Night light" "Invalid temperature: '$2' (1000-25000 K)" --icon="$ICON"
            exit 1
        fi
        stop
        if command -v gammastep >/dev/null; then
            setsid -f gammastep -m wayland -P -O "$TEMP" >/dev/null 2>&1
        elif command -v wlsunset >/dev/null; then
            setsid -f wlsunset -T "$((TEMP + 1))" -t "$TEMP" >/dev/null 2>&1
        else
            notify-send -u normal "Night light" "Install gammastep (or wlsunset)" --icon="$ICON"; exit 1
        fi
        notify-send -u low "Night light" "Color temperature: ${TEMP}K" --icon="$ICON"
        ;;
    off)
        stop
        notify-send -u low "Night light" "Disabled" --icon="$ICON"
        ;;
    status)
        if pgrep -u "$USER" -a gammastep; then :; else echo "night light off"; fi
        ;;
    *)
        echo "Usage: $0 set <kelvin> | off | status" >&2; exit 2 ;;
esac
