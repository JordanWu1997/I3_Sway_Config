#!/usr/bin/env bash
# ~/.config/sway/script/sway_lock_operator.sh
# Ported from i3_i3lock_operator.sh for sway.
# Replaced X11 tools:
#   - i3lock -n -t -f -i IMG    -> swaylock -f -F -s fill -i IMG
#                                  (-f daemonizes once the lock is shown, so swayidle's
#                                  before-sleep/lock handlers return right away; dunst
#                                  is un-paused by a background waiter after unlock)
#   - gnome-screenshot --file   -> grim -o OUTPUT (one blurred image per output)
#   - ~/.fehbg (current wallpaper) -> swaybg command line (-i PATH), ~/.fehbg as fallback
# Subcommands are unchanged: default | current_default_wallpaper | current_wallpaper |
# current_desktop | mannual_suspend
# If swaylock-effects is installed, current_desktop uses its --screenshots/--effect-blur.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

DEFAULT="$HOME/.config/i3/share/default_thinkpad_wallpaper.png"
CURRENT_DEFAULT="$HOME/.config/i3/share/default_wallpaper"
IMAGESIZE="1920x1080"
BLUR="0x12"
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway_lock"
SWAYLOCK_OPTS=(-f -F -s fill)

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_lock_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start swaylock with default wallpaper"
    echo "  [current_default_wallpaper]: start swaylock with current default wallpaper"
    echo "  [current_wallpaper]: start swaylock with current wallpaper"
    echo "  [current_desktop]: start swaylock with current desktop screenshot (blurred)"
    echo "  [mannual_suspend]: lock with blurred desktop screenshot, then suspend"
}

# ImageMagick 7 (magick) or 6 (convert / mogrify)
im_convert () {
    if command -v magick > /dev/null; then magick "$@"; else convert "$@"; fi
}
im_mogrify () {
    if command -v magick > /dev/null; then magick mogrify "$@"; else mogrify "$@"; fi
}

# Current wallpaper: swaybg -i PATH (sway), else the feh background file (i3)
current_wallpaper () {
    local cmdline path
    cmdline=$(pgrep -u "$(id -u)" -a -x swaybg | head -n 1)
    if [[ $cmdline =~ (-i|--image)[[:space:]]+([^[:space:]]+) ]]; then
        path=${BASH_REMATCH[2]}
    elif [[ -f $HOME/.fehbg ]]; then
        path=$(head -n 2 "$HOME/.fehbg" | tail -n 1 | cut -d"'" -f2)
    fi
    [[ -n $path && -f $path ]] && printf '%s\n' "$path" || printf '%s\n' "$DEFAULT"
}

swaylock_running () {
    pgrep -u "$(id -u)" -x swaylock > /dev/null
}

swaylock_has_effects () {
    swaylock --help 2>&1 | grep -q -- '--screenshots'
}

# Fill the array LOCK_ARGS with "-i OUTPUT:blurred.png" for each active output
build_desktop_lock_args () {
    local output image
    LOCK_ARGS=()
    if swaylock_has_effects; then
        LOCK_ARGS=(--screenshots --effect-blur 12x3)
        return 0
    fi
    mkdir -p "$CACHE_DIR"
    while read -r output; do
        [[ -n $output ]] || continue
        image="$CACHE_DIR/screen_${output}.png"
        grim -o "$output" "$image" 2> /dev/null || continue
        im_convert "$image" -blur "$BLUR" "$image"
        LOCK_ARGS+=(-i "${output}:${image}")
    done < <(swaymsg -t get_outputs -r | jq -r '.[] | select(.active) | .name')
    # No screenshot at all: plain colour instead of an unreadable empty lock
    (( ${#LOCK_ARGS[@]} )) || LOCK_ARGS=(-c 000000)
}

clean_desktop_images () {
    rm -f "$CACHE_DIR"/screen_*.png
}

# Run swaylock (daemonized) and call "$@" in the background once it exits
lock_then () {
    local pid
    swaylock "${SWAYLOCK_OPTS[@]}" "${LOCK_ARGS[@]}" || return 1
    pid=$(pgrep -u "$(id -u)" -n -x swaylock)
    if [[ -n $pid ]]; then
        ( tail --pid="$pid" -f /dev/null; "$@" ) > /dev/null 2>&1 < /dev/null &
        disown
    else
        "$@"
    fi
}

lock_operator () {
    local after=$2
    case $1 in
        "default")
            LOCK_ARGS=(-i "${DEFAULT}")
            lock_then ${after:-true}
            ;;
        "current_default_wallpaper")
            # If there is no current default, copy default from an existing default wallpaper
            [ ! -f "${CURRENT_DEFAULT}" ] && cp "${DEFAULT}" "${CURRENT_DEFAULT}"
            # If current default file extension does not end with png, convert it to a png file
            [ ! -f "${CURRENT_DEFAULT}.png" ] && im_mogrify -resize ${IMAGESIZE} -format png "${CURRENT_DEFAULT}"
            if [[ -f ${CURRENT_DEFAULT}.png ]]; then
                LOCK_ARGS=(-i "${CURRENT_DEFAULT}.png")
            else
                LOCK_ARGS=(-i "${CURRENT_DEFAULT}")
            fi
            lock_then ${after:-true}
            ;;
        "current_wallpaper")
            local current current_png
            current=$(current_wallpaper)
            if ( file "${current}" | grep -q PNG ); then
                current_png=${current}
            elif [[ -f ${current}.png ]]; then
                current_png=${current}.png
            # If current file is not a png file, convert it a to png file
            else
                im_mogrify -resize ${IMAGESIZE} -format png "${current}"
                current_png="$(dirname "${current}")/$(basename "${current}" | cut -d'.' -f1).png"
            fi
            LOCK_ARGS=(-i "${current_png}")
            lock_then ${after:-true}
            ;;
        "current_desktop")
            build_desktop_lock_args
            lock_then ${after:-clean_desktop_images}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

sway_lock_suspender () {
    # Lock (daemonized) with blurred screenshot of current desktop, then suspend.
    # swayidle's before-sleep handler sees swaylock running and does nothing.
    if ! swaylock_running; then
        build_desktop_lock_args
        swaylock "${SWAYLOCK_OPTS[@]}" "${LOCK_ARGS[@]}"
    fi
    # Suspend
    systemctl suspend
    # Clean screenshot cache
    clean_desktop_images
}

# Manual suspender
if [[ $1 == 'mannual_suspend' ]]; then
    sway_lock_suspender
    exit 0
fi

case $1 in
    default|current_default_wallpaper|current_wallpaper|current_desktop) ;;
    *) show_wrong_usage_message; echo; show_help_message; exit 1 ;;
esac

# Already locked (lock + before-sleep events can both fire): nothing to do
swaylock_running && exit 0

# Main
if [[ $(dunstctl is-paused 2> /dev/null) == 'false' ]]; then
    dunstctl set-paused true
    # Locker; notifications are resumed after unlock
    unpause_dunst () { [[ $1 != keep ]] && clean_desktop_images; dunstctl set-paused false; }
    if [[ $1 == current_desktop ]]; then
        lock_operator "$1" unpause_dunst || dunstctl set-paused false
    else
        lock_operator "$1" "unpause_dunst keep" || dunstctl set-paused false
    fi
else
    lock_operator "$1"
fi
