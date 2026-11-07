#!/usr/bin/env bash
# ~/.config/sway/script/sway_recorder.sh
# Screen recording on sway (replaces peek, which is X11-only and unmaintained).
# Uses wf-recorder (wlr-screencopy). Same key starts and stops a recording.
#
# Usage: sway_recorder.sh toggle region   # select a region with slurp
#        sway_recorder.sh toggle output   # record the focused output
#        sway_recorder.sh stop
ICON="$HOME/.config/i3/share/64x64/video_player.png"
OUT_DIR="$HOME/Videos"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/sway_recorder.pid"

running() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

stop() {
    if running; then
        kill -INT "$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
        notify-send -u low "Recorder" "Recording saved in $OUT_DIR" --icon="$ICON"
        return 0
    fi
    return 1
}

start() {
    command -v wf-recorder >/dev/null || { notify-send -u normal "Recorder" "Install wf-recorder" --icon="$ICON"; exit 1; }
    mkdir -p "$OUT_DIR"
    FILE="$OUT_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    case "$1" in
        region)
            GEOM=$(slurp) || exit 0
            setsid -f sh -c 'echo $$ > "$1"; exec wf-recorder -g "$2" -f "$3"' _ "$PIDFILE" "$GEOM" "$FILE" >/dev/null 2>&1 ;;
        output|*)
            OUTPUT=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name')
            setsid -f sh -c 'echo $$ > "$1"; exec wf-recorder -o "$2" -f "$3"' _ "$PIDFILE" "$OUTPUT" "$FILE" >/dev/null 2>&1 ;;
    esac
    notify-send -u low "Recorder" "Recording ($1)... press the same key again to stop" --icon="$ICON"
}

case "$1" in
    toggle) stop || start "${2:-output}" ;;
    stop)   stop || notify-send -u low "Recorder" "Nothing is recording" --icon="$ICON" ;;
    *)      echo "Usage: $0 toggle region|output | stop" >&2; exit 2 ;;
esac
