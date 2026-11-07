#!/usr/bin/env bash
# Ported from i3_window_decoractor.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config.d/i3_window.config -> ~/.config/sway/config.d/sway_window.config
#   i3-msg reload                          -> swaymsg reload
#   $bg/$fg/$c0..$c15 from set_from_resource (Xresources) -> the same variables are
#   defined on sway by `include ~/.cache/wal/colors-sway-i3` in ~/.config/sway/config,
#   so the written client.* lines are unchanged.
# The i3 version rewrote the 6 lines at fixed offsets below the "Color Palette"
# marker; this version rewrites the client.focused / focused_inactive / unfocused /
# urgent / placeholder / background lines found after that marker by name.
# (client.placeholder and client.background are accepted but ignored by sway.)

WINDOW_CONFIG="$HOME/.config/sway/config.d/sway_window.config"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_window_decoractor.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [default]: i3 default window colorscheme"
    echo "  [monochromic]: border color scheme in monochrmic style"
    echo "  [dirchromatic]: border color scheme in dichromatic style"
    echo "  [monochromic_inversed]: border color scheme in inversely monochromic style"
}

# Args: focused focused_inactive unfocused urgent placeholder background (values)
set_window_colors () {
    local tmp
    grep -q 'Color Palette' "$WINDOW_CONFIG" || {
        notify-send -u critical "Sway Window Decorator" "No 'Color Palette' marker in $WINDOW_CONFIG"
        return 1
    }
    tmp=$(mktemp) || return 1
    awk -v a="$1" -v b="$2" -v c="$3" -v d="$4" -v e="$5" -v f="$6" '
        BEGIN {
            v["client.focused"]          = "client.focused          " a
            v["client.focused_inactive"] = "client.focused_inactive " b
            v["client.unfocused"]        = "client.unfocused        " c
            v["client.urgent"]           = "client.urgent           " d
            v["client.placeholder"]      = "client.placeholder      " e
            v["client.background"]       = "client.background               " f
        }
        /Color Palette/ { palette = 1 }
        palette && ($1 in v) && !done[$1]++ { print v[$1]; next }
        { print }
    ' "$WINDOW_CONFIG" > "$tmp" && cat "$tmp" > "$WINDOW_CONFIG"
    rm -f -- "$tmp"
}

window_decoraction () {
    case $1 in
        "default")
            set_window_colors \
                '#4C7899 #285577 #FFFFFF #2E9EF4 #285577' \
                '#333333 #5F676A #FFFFFF #484E50 #5F676A' \
                '#333333 #222222 #888888 #292D2E #222222' \
                '#2F343A #900000 #FFFFFF #900000 #900000' \
                '#000000 #0C0C0C #FFFFFF #000000 #0C0C0C' \
                '#ffffff'
            ;;
        "monochromic")
            set_window_colors \
                '$c5     $c5     $c15    $c13    $c5' \
                '$c1     $c1     $c7     $c9     $c1' \
                '$c1     $c1     $c7     $c1     $c1' \
                '$c0     $c15    $c0     $c15    $c15' \
                '$c1     $c1     $c15    $c9     $c1' \
                '$transp'
            ;;
        "dirchromatic")
            set_window_colors \
                '$c13    $c5     $c15    $c11    $c13' \
                '$c9     $c1     $c7     $c10    $c9' \
                '$c1     $c1     $c7     $c12    $c1' \
                '$c0     $c15    $c0     $c15    $c0' \
                '$c1     $c1     $c15    $c14    $c1' \
                '$transp'
            ;;
        "monochromic_inversed")
            set_window_colors \
                '$c1     $c1     $c15    $c9     $c1' \
                '$c5     $c5     $c7     $c13    $c5' \
                '$c5     $c5     $c7     $c5     $c5' \
                '$c0     $c15    $c0     $c15    $c15' \
                '$c5     $c5     $c15    $c13    $c1' \
                '$transp'
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    swaymsg reload
}

# Main
window_decoraction "$1"
