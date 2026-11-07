#!/usr/bin/env bash
# ~/.config/sway/script/sway_toolkit_operator.sh
# Ported from i3_toolkit_operator.sh for sway.
# Replaced X11 tools:
#   - xkill                     -> slurp -r over visible windows, swaymsg [con_id=N] kill
#   - gpick / xcolor            -> grim -g "$(slurp -p)" | magick/convert -> hex
#   - flameshot gui --raw       -> grim -g "$(slurp)" - (OCR via tesseract, QR via zbarimg)
#   - xclip / xsel              -> wl-copy / wl-paste
#   - wmctrl -l / -l -x         -> swaymsg -t get_tree | jq (app_id or X11 instance)
#   - i3-msg [id=X] focus       -> swaymsg [con_id=N] focus
#   - xset s off/-dpms (caffeine) -> swayidle restarted without idle timeouts
#                                    (state in ${XDG_RUNTIME_DIR}/sway_caffeine)
#   - parcellite (X11 only)     -> cliphist (wl-paste --watch cliphist store)
#   - libinput-gestures         -> sway native `bindgesture` (kept if installed)
#   - oneko (X11 pointer only)  -> stub
#   - i3-msg exec               -> swaymsg exec

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"

ICON="$HOME/.config/i3/share/64x64/wrench.png"
CAFFEINE_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway_caffeine"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_toolkit_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_caffeine/disable_screensaver]: disable idle lock / screen blanking (swayidle)"
    echo "  [disable_caffeine/enable_screensaver]: enable idle lock / screen blanking (swayidle)"
    echo "  [kill_window]: click window on screen to kill"
    echo "  [pickup_color]: pick up color on screen"
    echo "  [get_screenshot_text]: screenshot, apply OCR to it and copy context to clipboard"
    echo "  [get_screenshot_qr]: screenshot, decode QR Code on it and copy context to clipboard"
    echo "  [collect_all_instances]: collect all window instances"
    echo "  [toggle_oneko]: toggle oneko on/off (not supported on sway)"
    echo "  [reload_parcellite]: reload clipboard manager (cliphist watchers)"
    echo "  [reload_ibus_daemon]: reload ibus daemon (input method manager)"
    echo "  [reload_gestures]: reload libinput-gestures daemon (sway: native bindgesture)"
    echo "  [show_brave_browser]: show brave-browser windows"
    echo "  [kill_process]: kill selected PID (use kill -9 command)"
    echo "  [test_audio_IO]: test audio IO by recording and playing (alsa: arecord and aplay)"
    echo "  [translate_clip]: translate item in current clipboard (trans: tranlate; wl-paste: clipboard)"
}

not_supported () {
    notify-send -u normal "sway_toolkit_operator.sh" "$1: not supported on sway/Wayland – $2"
    exit 1
}

# Function to convert lstart to formatted time
format_start_time() {
    date -d "$1 $2 $3 $4" +"%m-%d %H:%M:%S"
}

# ImageMagick 7 (magick) or 6 (convert)
im_convert () {
    if command -v magick > /dev/null; then magick "$@"; else convert "$@"; fi
}

# Region screenshot as PNG on stdout (replaces flameshot gui --raw)
region_screenshot () {
    local area
    area=$(slurp) || return 1
    grim -g "$area" -t png -
}

# Visible windows as slurp boxes with con_id label: "x,y wxh con_id"
visible_window_boxes () {
    swaymsg -t get_tree -r | jq -r '
        .. | objects
        | select((.type == "con" or .type == "floating_con") and .pid != null and .visible == true)
        | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height) \(.id)"'
}

# Let the user click a window; print its con_id
select_window_con_id () {
    local boxes picked
    boxes=$(visible_window_boxes)
    [[ -n $boxes ]] || return 1
    picked=$(printf '%s\n' "$boxes" | slurp -r -f '%x,%y %wx%h') || return 1
    # Match the picked geometry back to the con_id (works with every slurp version)
    awk -v g="$picked" '$1 " " $2 == g {print $3; exit}' <<< "$boxes"
}

# All windows: "con_id<TAB>app_id-or-instance<TAB>title"
window_list () {
    swaymsg -t get_tree -r | jq -r '
        .. | objects
        | select((.type == "con" or .type == "floating_con") and .pid != null)
        | [(.id | tostring),
           (.app_id // .window_properties.instance // .window_properties.class // "unknown"),
           (.name // "")] | @tsv'
}

caffeine_set () {
    printf '%s\n' "$1" > "$CAFFEINE_FILE"
    # Restart swayidle with (off) or without (on) idle timeouts, keeping the lock style
    "$SWAY_SCRIPT/sway_idle_operator.sh" start
}

toolkit_operation () {
    case $1 in
        'kill_window')
            notify-send -t 1500 -u low "Toolkit Mode" "Click Window to kill" --icon="${ICON}"
            CON_ID=$(select_window_con_id)
            [[ -n ${CON_ID} ]] && swaymsg "[con_id=${CON_ID}] kill" > /dev/null
            ;;
        'pickup_color')
            notify-send -t 1500 -u low "Toolkit Mode" "Select Color on Screen" --icon="${ICON}"
            POINT=$(slurp -p) || exit 0
            COLOR=$(grim -g "${POINT}" -t ppm - | im_convert - -format '%[hex:p{0,0}]' info: 2> /dev/null)
            [[ -n ${COLOR} ]] || exit 1
            COLOR="#${COLOR:0:6}"
            echo -n "${COLOR}" | wl-copy
            notify-send -u low "Toolkit Mode" "Pickup Color: ${COLOR}" --icon="${ICON}"
            ;;
        'get_screenshot_text')
            # Source: https://new.reddit.com/r/archlinux/comments/1bwq3au/what_is_your_linux_customization_that_makes_you/
            CONTEXT=$(region_screenshot | tesseract -l eng+chi_tra stdin stdout)
            echo "${CONTEXT}" | wl-copy
            notify-send -u low "Toolkit Mode" "${CONTEXT}" --icon="${ICON}"
            ;;
        'get_screenshot_qr')
            CONTEXT=$(region_screenshot | im_convert - -bordercolor white -border 20x20 PNG:- | zbarimg --quiet --raw - 2> /dev/null)

            if [ -n "${CONTEXT}" ]; then
                echo -n "${CONTEXT}" | wl-copy
                notify-send -u low "Toolkit Mode" "Decoded: ${CONTEXT}" --icon="${ICON}"
            else
                notify-send -u low "Toolkit Mode" "No QR or barcode detected." --icon="${ICON}"
            fi
            ;;
        'collect_all_instances')
            INSTANCE=$(window_list | awk -F'\t' '{printf "%s  %s  %s\n", $1, $2, $3}' | \
                rofi -dmenu -p 'Collect all' | awk '{print $2}')
            [[ -n "${INSTANCE}" ]] && "$SWAY_SCRIPT/sway_collect_all_instances.py" "${INSTANCE}"
            ;;
        'enable_caffeine'|'disable_screensaver')
            caffeine_set on
            notify-send -u low "Toolkit Mode" "Caffeine On (Disable idle lock / screen blanking)" --icon="${ICON}"
            ;;
        'disable_caffeine'|'enable_screensaver')
            caffeine_set off
            notify-send -u low "Toolkit Mode" "Caffeine Off (Enable idle lock / screen blanking)" --icon="${ICON}"
            ;;
        'toggle_oneko')
            not_supported toggle_oneko "oneko only follows the X11 pointer (no Wayland port)"
            ;;
        'reload_parcellite')
            if ! command -v cliphist > /dev/null || ! command -v wl-paste > /dev/null; then
                notify-send -u normal "sway_toolkit_operator.sh" "reload_parcellite: install cliphist and wl-clipboard (parcellite is X11-only)" --icon="${ICON}"
                exit 1
            fi
            pkill -u "$(id -u)" -f '^wl-paste .*--watch cliphist' 2> /dev/null
            swaymsg -- exec "wl-paste --type text --watch cliphist store" > /dev/null
            swaymsg -- exec "wl-paste --type image --watch cliphist store" > /dev/null
            notify-send -u low "Toolkit Mode" "Clipboard manager (cliphist) is reloaded" --icon="${ICON}"
            ;;
        'reload_ibus_daemon')
            # restarts the framework chosen by $default_input_method (ibus or fcitx5)
            swaymsg -- exec "$HOME/.config/sway/script/sway_input_method.sh restart" > /dev/null
            ;;
        'reload_gestures')
            if command -v libinput-gestures-setup > /dev/null; then
                swaymsg -- exec 'libinput-gestures-setup restart' > /dev/null
                notify-send -u low "Toolkit Mode" "libinput-gestures is reloaded" --icon="${ICON}"
            else
                notify-send -u low "Toolkit Mode" "Gestures are native on sway (bindgesture); reload the sway config instead" --icon="${ICON}"
            fi
            ;;
        'show_brave_browser')
            CON_ID=$(window_list | awk -F'\t' '$3 ~ / - Brave$/ {printf "%s  %s\n", $1, $3}' | \
                rofi -dmenu -p 'Brave-browser' | awk '{print $1}')
            if [[ -n ${CON_ID} ]] && swaymsg "[con_id=${CON_ID}] focus" > /dev/null; then
                if [[ -x $SWAY_SCRIPT/sway_cursor_operator.sh ]]; then
                    "$SWAY_SCRIPT/sway_cursor_operator.sh" move_cursor_inside_window
                fi
            fi
            ;;
        'kill_process')
            # Only show processes for the current user
            ps -u "$USER" -o pid,lstart,cmd --sort=pid --no-headers | \
                while read -r PID DAY MONTH DATE TIME YEAR CMD; do
                    START=$(format_start_time "$DAY" "$MONTH" "$DATE" "$TIME" "$YEAR")
                    printf "%5s  %s  %s\n" "$PID" "$START" "$CMD"
                done | rofi -dmenu -i -p "Select your process to kill [${USER}]" \
                    -config "$HOME/.config/rofi/config_singlecol.rasi" | {
                read -r PID _
                # Early stop
                [ -z "$PID" ] && exit 0
                # Confirmation
                CONFIRM=$(echo -e "No\nYes" | rofi -dmenu -p "Kill PID $PID?")
                if [[ "$CONFIRM" == "Yes" ]]; then
                    kill -9 "$PID" && \
                        notify-send "Toolkit Mode" "Killed PID $PID" --icon ${ICON} || \
                        notify-send "Toolkit Mode" "Failed to kill PID $PID" --icon ${ICON}
                fi
            }
            ;;
        'test_audio_IO')
            TEMP_FILE="default_test.wav"; DURATION=5
            notify-send "Toolkit Mode" "Recording from DEFAULT input for $DURATION secs..." --icon ${ICON}
            # -f cd: 16 bit, 44100Hz, Stereo
            # -d: duration in seconds
            # -q: quiet mode (cleans up output)
            arecord -D default -f cd -d $DURATION -q $TEMP_FILE
            if [ $? -ne 0 ]; then
                notify-send "Toolkit Mode" "ERROR: Failed to record. Is your default input busy?" --icon ${ICON}
                exit 1
            fi
            # 2. Check if file is silent (Volume Meter Check)
            # We use 'sox' if available, or just check file size
            FILE_SIZE=$(stat -c%s "$TEMP_FILE")
            if [ "$FILE_SIZE" -lt 1000 ]; then
                notify-send "Toolkit Mode" "WARNING: The recorded file is unusually small. Check connections." --icon ${ICON}
            fi
            # 3. Test Playback
            notify-send "Toolkit Mode" "Playing back to DEFAULT output..." --icon ${ICON}
            aplay -D default -q $TEMP_FILE
            if [ $? -ne 0 ]; then
                notify-send "Toolkit Mode" "ERROR: Playback failed. Check if default output is muted." --icon ${ICON}
            fi
            # Cleanup
            rm -f $TEMP_FILE
            ;;
        'translate_clip')
            # Standard "Copy" buffer
            TEXT=$(wl-paste --no-newline 2> /dev/null)
            if [ -z "$TEXT" ]; then
                notify-send "Translation Error" "Clipboard is empty." --icon="$HOME/.config/i3/share/64x64/language.png"
                exit 1
            fi
            # trans -id returns the language code (e.g., en, zh-CN, zh-TW)
            LANG_ID=$(trans -id -no-ansi "${TEXT}" | grep Code | awk '{print $2}' | tr -d '\r')
            # Translate input to English by defualt, unless the input is English then translate to Traditional Chinese (zh-TW)
            [[ ${LANG_ID} == en* ]] && TARGET="zh-TW" || TARGET="en"
            # -b (brief) mode provides only the translated text
            RESULT=$(trans -b ":${TARGET}" "${TEXT}")
            notify-send "Toolkit Mode" "Translation (${LANG_ID} -> ${TARGET})\n${RESULT}" --icon ${ICON}
            echo "${RESULT}" | wl-copy
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
toolkit_operation "$@"
