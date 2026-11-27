#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Dim the screen and warn shortly before the idle lock
###########################################################

# Requirements:
#   xrandr (X11) or brightnessctl (Wayland), notify-send

# Usage: i3_idle_dim.sh [notifier|dim|restore]
#   notifier (default): dim, wait until killed, then restore. For i3: xss-lock runs
#       it as --notifier when the X screen saver activates and kills it when you
#       touch the keyboard/mouse or when the locker starts.
#       The warning time is the screen saver cycle (xset s <timeout> <cycle>) set in
#       i3_toolkit_operator.sh disable_caffeine.
#   dim / restore: one-shot steps, for swayidle "timeout ... resume ...".
#
# X11 (i3): every active output is dimmed with `xrandr --brightness` (software dim,
#   external monitors included); each output's previous brightness is restored.
#   A redshift tint is kept, as xrandr keeps the current colour curve.
# Wayland (sway): xrandr cannot reach the outputs, so only the built-in panel's
#   backlight is dimmed (brightnessctl). External monitors get the notification only.

DIM_BRIGHTNESS=0.3   # X11: xrandr brightness while dimmed (1.0 = normal)
DIM_PERCENT=10       # Wayland: backlight percent while dimmed
WARN_SECONDS=10
ICON="$HOME/.config/i3/share/64x64/wrench.png"
# Present while there is a saved brightness of ours to restore
XRANDR_STATE="${XDG_RUNTIME_DIR:-/tmp}/idle_dim_xrandr"
BACKLIGHT_STATE="${XDG_RUNTIME_DIR:-/tmp}/idle_dim_saved"

is_x11 () {
    [[ -z $WAYLAND_DISPLAY && -n $DISPLAY ]]
}

# "output brightness" for every connected output that is switched on
xrandr_brightness () {
    xrandr --verbose | awk '
        /^[^ \t]+ connected/ { out = ($3 ~ /^[0-9]+x[0-9]+/ || $4 ~ /^[0-9]+x[0-9]+/) ? $1 : "" }
        /^[ \t]+Brightness:/ && out != "" { print out, $2; out = "" }'
}

dim_xrandr () {
    local output _
    # A state file left from an earlier dim holds the real brightness: keep it
    [[ -e $XRANDR_STATE ]] || xrandr_brightness > "$XRANDR_STATE"
    while read -r output _; do
        xrandr --output "$output" --brightness "$DIM_BRIGHTNESS"
    done < "$XRANDR_STATE"
}

dim_backlight () {
    local percent
    [[ -e $BACKLIGHT_STATE ]] && return 0
    # Machine-readable line: device,class,current,percent%,max
    percent=$(brightnessctl -m 2>/dev/null | head -n 1 | cut -d, -f4 | tr -d '%')
    # Never raise a backlight that is already darker than the dim level
    if [[ $percent =~ ^[0-9]+$ ]] && (( percent > DIM_PERCENT )); then
        brightnessctl -q -s set "${DIM_PERCENT}%" && : > "$BACKLIGHT_STATE"
    fi
}

dim () {
    if is_x11; then dim_xrandr; else dim_backlight; fi
    notify-send -u normal -t $(( WARN_SECONDS * 1000 )) -a "Screen lock" \
        "Locking in ${WARN_SECONDS} s" "Move the mouse or press a key to stay unlocked" \
        --icon="$ICON"
}

restore () {
    local output level
    if [[ -e $XRANDR_STATE ]]; then
        while read -r output level; do
            xrandr --output "$output" --brightness "$level"
        done < "$XRANDR_STATE"
        rm -f "$XRANDR_STATE"
    fi
    if [[ -e $BACKLIGHT_STATE ]]; then
        rm -f "$BACKLIGHT_STATE"
        brightnessctl -q -r
    fi
}

case ${1:-notifier} in
    notifier)
        trap 'exit 0' TERM INT
        trap 'restore; kill "$sleeper" 2>/dev/null' EXIT
        dim
        sleep infinity &
        sleeper=$!
        wait
        ;;
    dim)
        dim
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: i3_idle_dim.sh [notifier|dim|restore]"
        exit 1
esac
