#!/usr/bin/env bash
# Ported from i3_conky_monitor_display.sh for sway.
# Replaced X11 tools:
#   - xrandr --primary/--left-of (used to steer conky to a head) -> output focus trick
#     (a layer-shell surface without an explicit output opens on the focused output)
#   - i3-msg exec / i3-msg restart -> setsid -f conky (no restart on sway)
#   - conky X11 own_window -> Wayland-patched copy of the config (out_to_wayland = true)
#     written to ${XDG_RUNTIME_DIR:-/tmp}/sway_conky/. The user's conky configs are never edited.
# If conky was built without Wayland support it falls back to the unmodified config
# running under XWayland (output selection is then not possible).

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"

CONKY_CONFIGS=(
    "$HOME/.config/conky/conky_config_bindkey"
    "$HOME/.config/conky/conky_config_system"
)
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/sway_conky"
PRIMARY_STATE="${XDG_RUNTIME_DIR:-/tmp}/sway_primary_output"
# Seconds to keep the target output focused while conky maps its surface
CONKY_MAP_DELAY="${CONKY_MAP_DELAY:-1.5}"
ICON="$HOME/.config/i3/share/64x64/monitor.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_conky_monitor_display.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [all]: conky shows on every active output"
    echo "  [primary]: conky shows on primary output (see sway_display_operator.sh *_primary)"
    echo "  [primary_only]: conky only shows on primary output (kills other conky first)"
    echo "  [eDP1]: conky shows on the internal panel (eDP-*) only"
    echo "  [default]: same as [primary]"
    echo "  [bindkey_on|bindkey_off]: start/stop only the bindkey conky (on primary output)"
    echo "  [system_on|system_off]: start/stop only the system conky (on primary output)"
}

conky_has_wayland () {
    conky -v 2>/dev/null | grep -qi 'wayland'
}

# Create a Wayland-patched copy of a conky config and print its path
patch_config () {
    local src=$1 dst
    mkdir -p "$RUNTIME_DIR" || return 1
    dst="$RUNTIME_DIR/$(basename "$src")"
    # Drop X-only / conflicting keys, then force Wayland output right after the opening brace
    sed -E \
        -e '/^[[:space:]]*(out_to_x|out_to_wayland|xinerama_head|own_window_type)[[:space:]]*=/d' \
        -e 's/^([[:space:]]*conky\.config[[:space:]]*=[[:space:]]*\{)[[:space:]]*$/\1\n\tout_to_x = false,\n\tout_to_wayland = true,/' \
        "$src" > "$dst" || return 1
    printf '%s\n' "$dst"
}

focused_output () {
    swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name' | head -n1
}

active_outputs () {
    swaymsg -t get_outputs -r | jq -r '.[] | select(.active) | .name'
}

# "Primary" has no meaning on sway: use the output recorded by sway_display_operator.sh,
# else the output that holds workspace 1, else the focused output.
primary_output () {
    local out
    if [[ -r "$PRIMARY_STATE" ]]; then
        out=$(<"$PRIMARY_STATE")
        if active_outputs | grep -qxF "$out"; then
            printf '%s\n' "$out"; return
        fi
    fi
    out=$(swaymsg -t get_workspaces -r | jq -r '[.[] | select(.num == 1)][0].output // empty')
    [[ -n "$out" ]] || out=$(focused_output)
    printf '%s\n' "$out"
}

internal_output () {
    swaymsg -t get_outputs -r | jq -r '[.[] | select(.active and (.name | test("^(eDP|LVDS|DSI)")))][0].name // empty'
}

# Launch conky configs (default: both) on the given output (empty = focused output)
launch_conky_on () {
    local target=$1 previous cfg run_cfg
    shift
    local -a configs=("$@")
    (( ${#configs[@]} )) || configs=("${CONKY_CONFIGS[@]}")
    if ! conky_has_wayland; then
        # XWayland fallback: unmodified config, no output selection
        for cfg in "${configs[@]}"; do
            setsid -f conky -c "$cfg" &> /dev/null
        done
        return 0
    fi
    previous=$(focused_output)
    if [[ -n "$target" && "$target" != "$previous" ]]; then
        swaymsg focus output "\"$target\"" > /dev/null
    fi
    for cfg in "${configs[@]}"; do
        run_cfg=$(patch_config "$cfg") || continue
        setsid -f conky -c "$run_cfg" &> /dev/null
    done
    if [[ -n "$target" && -n "$previous" && "$target" != "$previous" ]]; then
        sleep "$CONKY_MAP_DELAY"
        swaymsg focus output "\"$previous\"" > /dev/null
    fi
}

warn_no_wayland_selection () {
    conky_has_wayland || notify-send -u low "Conky" \
        "conky lacks Wayland support: running under XWayland, output selection ignored" --icon="$ICON"
}

conky_display () {
    local out
    case $1 in
        "all")
            killall conky &> /dev/null; sleep 0.5
            warn_no_wayland_selection
            if conky_has_wayland; then
                while read -r out; do
                    [[ -n "$out" ]] && launch_conky_on "$out"
                done < <(active_outputs)
            else
                launch_conky_on ""
            fi
            ;;
        "primary"|"default")
            launch_conky_on "$(primary_output)"
            ;;
        "primary_only")
            killall conky &> /dev/null; sleep 0.5
            launch_conky_on "$(primary_output)"
            ;;
        "eDP1")
            killall conky &> /dev/null; sleep 0.5
            warn_no_wayland_selection
            out=$(internal_output)
            [[ -n "$out" ]] || out=$(primary_output)
            launch_conky_on "$out"
            ;;
        "bindkey_on")
            launch_conky_on "$(primary_output)" "${CONKY_CONFIGS[0]}"
            ;;
        "system_on")
            launch_conky_on "$(primary_output)" "${CONKY_CONFIGS[1]}"
            ;;
        "bindkey_off")
            # Matches both the original and the Wayland-patched copy
            pkill -f 'conky -c .*conky_config_bindkey' &> /dev/null
            ;;
        "system_off")
            pkill -f 'conky -c .*conky_config_system' &> /dev/null
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
conky_display "$1"
