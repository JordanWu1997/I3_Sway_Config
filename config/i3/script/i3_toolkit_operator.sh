#!/usr/bin/env bash

ICON="$HOME/.config/i3/share/64x64/wrench.png"

toolkit_notice() {
    notify-send -u low "Toolkit Mode" "$1" --icon="$ICON"
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 && return 0
    toolkit_notice "Missing command: $1"
    return 1
}

toolkit_workdir() {
    local base=${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}
    mkdir -p -- "$base" && mktemp -d "$base/i3-toolkit.XXXXXX"
}

read_screenshot() {
    local workdir image captured reader voice
    require_tool flameshot && require_tool tesseract || return 1
    if command -v espeak >/dev/null 2>&1; then
        reader=espeak
    elif command -v espeak-ng >/dev/null 2>&1; then
        reader=espeak-ng
    else
        toolkit_notice 'Install espeak or espeak-ng to read screenshots'
        return 1
    fi

    workdir=$(toolkit_workdir) || { toolkit_notice 'Could not create a temporary directory'; return 1; }
    image=$workdir/region.png
    if ! flameshot gui --raw > "$image" || [[ ! -s $image ]]; then
        rm -rf -- "$workdir"
        return 0  # Selection was cancelled.
    fi
    captured=$(tesseract -l eng+chi_tra "$image" stdout 2>/dev/null)
    rm -rf -- "$workdir"
    if [[ -z ${captured//[[:space:]]/} ]]; then
        toolkit_notice 'No readable text found in the selected region'
        return 1
    fi
    voice=${I3_READER_VOICE:-en}
    toolkit_notice 'Reading selected text aloud'
    printf '%s\n' "$captured" | "$reader" -v "$voice" -s "${I3_READER_SPEED:-165}" --stdin
}

dictation_state_dir() {
    local display_key=${DISPLAY:-unknown}
    display_key=${display_key//[^a-zA-Z0-9]/_}
    printf '%s/i3-dictation-%s\n' "${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}" "$display_key"
}

dictation_ready() {
    local state_dir target
    state_dir=$(dictation_state_dir)
    umask 077
    mkdir -m 700 -p -- "$state_dir" || return 1
    if command -v xdotool >/dev/null 2>&1; then
        target=$(xdotool getactivewindow 2>/dev/null) || target=
        [[ $target =~ ^[0-9]+$ ]] && printf '%s\n' "$target" > "$state_dir/target_window"
    fi
    toolkit_notice 'Hold Space to copy speech with a Paste action, or Shift+Space to type into this app. Release to transcribe.'
}

dictation_recorder_alive() {
    local pid tick stat
    local -a fields
    [[ -r $1/recorder ]] || return 1
    read -r pid tick < "$1/recorder" || return 1
    [[ $pid =~ ^[0-9]+$ && $tick =~ ^[0-9]+$ && -r /proc/$pid/stat ]] || return 1
    IFS= read -r stat < "/proc/$pid/stat" || return 1
    read -r -a fields <<< "${stat##*) }"
    [[ ${fields[0]:-} != Z && ${fields[19]:-} == "$tick" ]]
}

dictation_notify() {
    local id=
    [[ -r $DICTATION_DIR/notice_id ]] && read -r id < "$DICTATION_DIR/notice_id"
    if [[ $id =~ ^[0-9]+$ ]]; then
        notify-send -r "$id" -u normal -t "$1" "${3:-Dictation}" "$2" --icon="$ICON"
    else
        notify-send -u normal -t "$1" "${3:-Dictation}" "$2" --icon="$ICON"
    fi
}

dictation_type_text() {
    local target=$1 transcript=$2
    [[ $target =~ ^[0-9]+$ ]] && command -v xdotool >/dev/null 2>&1 &&
        xdotool getwindowname "$target" >/dev/null 2>&1 || return 1
    i3-msg 'mode "default"' >/dev/null &&
        xdotool windowactivate --sync "$target" &&
        printf '%s' "$transcript" | xdotool type --clearmodifiers --delay 1 --file -
}

dictation_paste_text() {
    local target=$1 transcript=$2
    [[ $target =~ ^[0-9]+$ ]] && command -v xdotool >/dev/null 2>&1 &&
        xdotool getwindowname "$target" >/dev/null 2>&1 || return 1
    command -v xclip >/dev/null 2>&1 || return 1
    printf '%s' "$transcript" | xclip -selection clipboard -in || return 1
    i3-msg 'mode "default"' >/dev/null &&
        xdotool windowactivate --sync "$target" &&
        xdotool key --clearmodifiers ctrl+v
}

dictation_offer_paste() {
    local transcript=$1 target=$2 id=$3 choice
    local -a replace=()
    [[ $id =~ ^[0-9]+$ ]] && replace=(-r "$id")
    choice=$(notify-send "${replace[@]}" -u normal -t 30000 \
        -A paste='Paste into original app' \
        'Dictation · copied to clipboard' "$transcript" --icon="$ICON") || return 0
    if [[ $choice == paste ]]; then
        if ! dictation_paste_text "$target" "$transcript"; then
            toolkit_notice 'Could not paste dictation into the original app; text is still on the clipboard'
        fi
    fi
}

resolve_whisper_backend() {
    local model=${I3_WHISPER_MODEL:-base}
    DICTATION_WHISPER_CLI=$(command -v whisper-cli 2>/dev/null || true)
    [[ -n $DICTATION_WHISPER_CLI ]] || DICTATION_WHISPER_CLI=$HOME/.local/bin/whisper-cli
    DICTATION_MODEL_PATH=${I3_WHISPER_MODEL_PATH:-$HOME/.local/share/whisper.cpp/models/ggml-base.bin}
    if [[ -x $DICTATION_WHISPER_CLI && -s $DICTATION_MODEL_PATH ]]; then
        DICTATION_BACKEND=cpp
        return 0
    fi
    DICTATION_MODEL_DIR=${I3_WHISPER_MODEL_DIR:-$HOME/.cache/whisper}
    if command -v whisper >/dev/null 2>&1 && [[ -s $DICTATION_MODEL_DIR/$model.pt ]]; then
        DICTATION_BACKEND=python
        return 0
    fi
    toolkit_notice "Local Whisper is not ready. Install whisper-cli and set I3_WHISPER_MODEL_PATH to a multilingual ggml model, or install OpenAI Whisper and cache its $model model."
    return 1
}

transcribe_dictation() {
    local audio=$1 output=$2 model=${I3_WHISPER_MODEL:-base}
    local -a language=()
    if [[ $DICTATION_BACKEND == cpp ]]; then
        "$DICTATION_WHISPER_CLI" -m "$DICTATION_MODEL_PATH" -f "$audio" \
            -l "${I3_WHISPER_LANGUAGE:-auto}" -nt -np -otxt -of "${output%.txt}" \
            >/dev/null 2>"$DICTATION_DIR/whisper.log"
    else
        [[ -z ${I3_WHISPER_LANGUAGE:-} || $I3_WHISPER_LANGUAGE == auto ]] || language=(--language "$I3_WHISPER_LANGUAGE")
        whisper "$audio" --model "$model" --model_dir "$DICTATION_MODEL_DIR" \
            --output_format txt --output_dir "$DICTATION_DIR" --verbose False \
            "${language[@]}" >"$DICTATION_DIR/whisper.log" 2>&1
    fi
}

dictation_start() {
    local result=${1:-type} state_dir pid stat target
    local -a fields
    [[ $result == type || $result == copy ]] || return 1
    require_tool parec && require_tool timeout || return 1
    resolve_whisper_backend || return 1
    state_dir=$(dictation_state_dir)
    if [[ -d $state_dir ]]; then
        [[ -d $state_dir/processing ]] && return 0
        dictation_recorder_alive "$state_dir" && return 0  # Ignore Space auto-repeat.
        if [[ -e $state_dir/recorder ]] ||
            { [[ -d $state_dir/starting ]] && (( $(date +%s) - $(stat -c %Y "$state_dir/starting") > 3 )); }; then
            rm -rf -- "$state_dir"
        fi
    fi
    umask 077
    mkdir -m 700 -p -- "$(dirname -- "$state_dir")"
    mkdir -m 700 -p -- "$state_dir" || return 1
    # The mode-entry command and the first Space press can run concurrently.
    if [[ ! -s $state_dir/target_window ]] && command -v xdotool >/dev/null 2>&1; then
        target=$(xdotool getactivewindow 2>/dev/null) || target=
        [[ $target =~ ^[0-9]+$ ]] && printf '%s\n' "$target" > "$state_dir/target_window"
    fi
    mkdir -- "$state_dir/starting" 2>/dev/null || return 0  # Ignore key auto-repeat.
    printf '%s\n' "$result" > "$state_dir/result_action"
    # A 60-second cap prevents an orphaned recording if i3 misses KeyRelease.
    timeout --signal=TERM --kill-after=2s 60s \
        parec --device=@DEFAULT_SOURCE@ --format=s16le --rate=16000 --channels=1 --raw \
        >"$state_dir/speech.raw" 2>"$state_dir/record.log" &
    pid=$!
    if [[ ! -r /proc/$pid/stat ]]; then
        rm -rf -- "$state_dir"
        toolkit_notice 'Microphone recording failed; check the default input device'
        return 1
    fi
    IFS= read -r stat < "/proc/$pid/stat"
    read -r -a fields <<< "${stat##*) }"
    printf '%s %s\n' "$pid" "${fields[19]}" > "$state_dir/recorder"
    notify-send -p -u low -t 60000 'Dictation' "Listening… release Space to ${result}." \
        --icon="$ICON" > "$state_dir/notice_id" || true
    : > "$state_dir/ready"
}

dictation_finish() {
    local action=$1 state_dir pid tick audio raw_audio raw_text transcript result target notice_id=
    local attempt
    state_dir=$(dictation_state_dir)
    for attempt in {1..40}; do
        [[ -e $state_dir/ready ]] && break
        sleep 0.05  # KeyRelease may reach this process before KeyPress finishes setup.
    done
    if [[ $action == cancel && ! -e $state_dir/recorder ]]; then
        rm -rf -- "$state_dir"
        return 0
    fi
    [[ -e $state_dir/ready && -r $state_dir/recorder ]] || return 0
    [[ ! -d $state_dir/processing ]] || return 0
    mkdir -- "$state_dir/processing" 2>/dev/null || return 0
    DICTATION_DIR=$state_dir
    trap 'rm -rf -- "$DICTATION_DIR"' EXIT
    read -r pid tick < "$state_dir/recorder"
    if dictation_recorder_alive "$state_dir"; then
        kill -TERM "$pid" 2>/dev/null || true
        for attempt in {1..50}; do
            dictation_recorder_alive "$state_dir" || break
            sleep 0.05
        done
    fi
    if [[ $action == cancel ]]; then
        dictation_notify 2000 'Cancelled'
        return 0
    fi
    if ! command -v ffmpeg >/dev/null 2>&1; then
        dictation_notify 5000 'Missing ffmpeg'
        return 1
    fi
    resolve_whisper_backend || { dictation_notify 5000 'Local Whisper is not ready'; return 1; }
    raw_audio=$state_dir/speech.raw
    audio=$state_dir/speech.wav
    if [[ ! -s $raw_audio ]] || (( $(stat -c%s -- "$raw_audio") < 3200 )); then
        dictation_notify 5000 'No audio was recorded'
        return 1
    fi
    if ! ffmpeg -hide_banner -loglevel error -f s16le -ar 16000 -ac 1 \
        -i "$raw_audio" -c:a pcm_s16le "$audio"; then
        dictation_notify 5000 'Could not prepare recorded audio for Whisper'
        return 1
    fi

    dictation_notify 60000 'Transcribing locally…'
    raw_text=$state_dir/speech.txt
    transcribe_dictation "$audio" "$raw_text" || {
        dictation_notify 5000 'Whisper transcription failed'
        return 1
    }
    [[ -s $raw_text ]] || { dictation_notify 5000 'No speech was recognized'; return 1; }
    transcript=$(cat -- "$raw_text")
    [[ -n ${transcript//[[:space:]]/} ]] || { dictation_notify 5000 'No speech was recognized'; return 1; }
    read -r result < "$state_dir/result_action"
    if [[ $result == copy ]]; then
        if command -v xclip >/dev/null 2>&1 && printf '%s' "$transcript" | xclip -selection clipboard -in; then
            read -r target < "$state_dir/target_window" 2>/dev/null || target=
            [[ -r $state_dir/notice_id ]] && read -r notice_id < "$state_dir/notice_id"
            # Release the recording state while the notification waits for an action.
            trap - EXIT
            rm -rf -- "$state_dir"
            if [[ $target =~ ^[0-9]+$ ]]; then
                dictation_offer_paste "$transcript" "$target" "$notice_id"
            else
                notify-send -u normal -t 30000 'Dictation · copied to clipboard' "$transcript" --icon="$ICON"
            fi
        else
            dictation_notify 5000 'Could not copy transcript to clipboard'
            return 1
        fi
    else
        read -r target < "$state_dir/target_window" 2>/dev/null || target=
        if ! dictation_type_text "$target" "$transcript"; then
            dictation_notify 5000 'Could not type transcript into the original app'
            return 1
        fi
        dictation_notify 30000 "$transcript" 'Dictation · typed into app'
    fi
}

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_toolkit_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_caffeine/disable_screensaver]: disable X screensaver"
    echo "  [disable_caffeine/enable_screensaver]: enable X screensaver"
    echo "  [kill_window]: click window on screen to kill (X window)"
    echo "  [pickup_color]: pick up color on screen (X window)"
    echo "  [get_screenshot_text]: screenshot, apply OCR to it and copy context to clipboard"
    echo "  [read_screenshot]: select a region, OCR it, and read it aloud with espeak"
    echo "  [get_screenshot_qr]: screenshot, decode QR Code on it and copy context to clipboard"
    echo "  [dictation_ready/dictation_start/dictation_stop/dictation_cancel]: hold Space to copy with a Paste action, or Shift+Space to type dictated text"
    echo "  [collect_all_instances]: collect all window instances"
    echo "  [toggle_oneko]: toggle oneko on/off"
    echo "  [reload_parcellite]: reload parcellite (clipboard manager)"
    echo "  [reload_ibus_daemon]: reload ibus daemon (input method manager)"
    echo "  [reload_gestures]: reload libinput-gestures daemon (trackpad gesture)"
    echo "  [show_brave_browser]: show brave=browser windows"
    echo "  [kill_process]: kill selected PID (use kill -9 command)"
    echo "  [test_audio_IO]: test audio IO by recording and playing (alsa: arecord and aplay)"
    echo "  [translate_clip]: translate item in current clipboard (trans: tranlate; xclip or xsel: clipboard)"
}

# Function to convert lstart to formatted time
format_start_time() {
    date -d "$1 $2 $3 $4" +"%m-%d %H:%M:%S"
}

toolkit_operation () {
    case $1 in
        'kill_window')
            notify-send -t 1500 -u low "Toolkit Mode" "Click Window to kill" --icon="${ICON}"
            xkill
            ;;
        'pickup_color')
            notify-send -t 1500 -u low "Toolkit Mode" "Select Color on Screen" --icon="${ICON}"
            # Pickup color (requires xcolor, and xclip or xsel)
            #COLOR=$(xcolor --format 'HEX' -S 3)
            # Pickup color (requires gpick and xclip or xsel)
            COLOR=$(gpick --single --no-start --output)
            echo "${COLOR}" | xsel -i
            notify-send -u low "Toolkit Mode" "Pickup Color: ${COLOR}" --icon="${ICON}"
            ;;
        'get_screenshot_text')
            # Source: https://new.reddit.com/r/archlinux/comments/1bwq3au/what_is_your_linux_customization_that_makes_you/
            CONTEXT=$(flameshot gui --raw | tesseract -l eng+chi_tra stdin stdout)
            echo "${CONTEXT}" | xclip -in -selection clipboard
            notify-send -u low "Toolkit Mode" "${CONTEXT}" --icon="${ICON}"
            ;;
        'read_screenshot')
            read_screenshot
            ;;
        'dictation_ready')
            dictation_ready
            ;;
        'dictation_start')
            dictation_start "${2:-type}"
            ;;
        'dictation_stop')
            dictation_finish stop
            ;;
        'dictation_cancel')
            dictation_finish cancel
            ;;
        'get_screenshot_qr')
            CONTEXT=$(flameshot gui --raw | convert - -bordercolor white -border 20x20 PNG:- | zbarimg --quiet --raw - 2>/dev/null)

            if [ -n "${CONTEXT}" ]; then
                echo -n "${CONTEXT}" | xclip -in -selection clipboard
                notify-send -u low "Toolkit Mode" "Decoded: ${CONTEXT}" --icon="${ICON}"
            else
                notify-send -u low "Toolkit Mode" "No QR or barcode detected." --icon="${ICON}"
            fi
            ;;
        'collect_all_instances')
            INSTANCE=$(wmctrl -l -x | rofi -dmenu -p 'Collect all' | cut -d' ' -f4 | cut -d. -f1)
            [[ -n "${INSTANCE}" ]] && $I3_SCRIPT/i3_collect_all_instances.py ${INSTANCE}
            ;;
        'enable_caffeine'|'disable_screensaver')
            xset s off; xset -dpms; xset s noblank
            notify-send -u low "Toolkit Mode" "Caffeine On (Disable X Screensaver)" --icon="${ICON}"
            ;;
        'disable_caffeine'|'enable_screensaver')
            # Screen saver at 590 s: xss-lock runs i3_idle_dim.sh (dim + warning), then
            # locks 10 s later at the cycle. Screen off (DPMS) at 610 s, after the lock.
            xset s 590 10 dpms 610 610 610; xset s blank
            notify-send -u low "Toolkit Mode" "Caffeine Off (Enable X Screensaver)" --icon="${ICON}"
            ;;
        'toggle_oneko')
            if $(killall oneko); then
                notify-send -u low "Toolkit Mode" "Oneko is killed" --icon="${ICON}"
            else
                oneko -fg black -bg white -neko -speed 50
            fi
            ;;
        'reload_parcellite')
            PARCELLITE_PID=$(pgrep -l 'parcellite' | cut -d' ' -f1)
            if [[ -n ${PARCELLITE_PID} ]]; then
                kill ${PARCELLITE_PID}
            fi
            # Send stderr to null to prevent "Error converting selection from UTF8_STRING" log spamming
            i3-msg -- exec --no-startup-id 'parcellite 2> /dev/null'
            notify-send -u low "Toolkit Mode" "Parcellite is reloaded" --icon="${ICON}"
            ;;
        'reload_ibus_daemon')
            IBUS_PID=$(pgrep -l 'ibus-daemon' | cut -d' ' -f1)
            if [[ -n ${IBUS_PID} ]]; then
                kill ${IBUS_PID}
            fi
            i3-msg -- exec --no-startup-id 'ibus-daemon -r -d -x 2'
            notify-send -u low "Toolkit Mode" "ibus-daemon is reloaded" --icon="${ICON}"
            ;;
        'reload_gestures')
            i3-msg -- exec --no-startup-id 'libinput-gestures-setup restart'
            notify-send -u low "Toolkit Mode" "libinput-gestures is reloaded" --icon="${ICON}"
            ;;
        'show_brave_browser')
            WINDOW_ID=$(wmctrl -l | grep ' - Brave$' | rofi -dmenu -p 'Brave-browser' | cut -d' ' -f1)
            [[ -n ${WINDOW_ID} ]] && i3-msg "[id="${WINDOW_ID}"] focus" && $I3_SCRIPT/i3_cursor_operator.sh move_cursor_inside_window
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
            # Using xclip -selection clipboard to get the standard "Copy" buffer
            TEXT=$(xclip -o -selection clipboard)
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
            echo "${RESULT}" | xclip -in -selection clipboard
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
