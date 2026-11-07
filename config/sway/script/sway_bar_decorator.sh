#!/usr/bin/env bash
# Ported from i3_bar_decorator.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config.d/i3_bar.config -> ~/.config/sway/config.d/sway_bar.config
#   i3-msg reload                       -> swaymsg reload
# The i3 version rewrote fixed line offsets below the "<bar> workspace color"
# marker. This version rewrites the same lines by key name (background,
# statusline, separator, focused_/active_/inactive_/urgent_workspace,
# binding_mode) inside the colors block that follows each marker, so blank or
# extra comment lines in the block do not break it. Output lines are identical.

BAR_CONFIG="$HOME/.config/sway/config.d/sway_bar.config"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_bar_decorator.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [i3]: i3 default colorscheme"
    echo "  [pywal]: pywal colorscheme"
}

# Rewrite the colors of the block after "<marker>" ('' = active, '#' = commented)
# and the bumblebee-status theme line.
apply_bar_colors () {
    local prefix=$1 theme=$2 tmp
    tmp=$(mktemp) || return 1
    awk -v p="$prefix" -v theme="$theme" '
        BEGIN {
            v["background"]         = "background $bg"
            v["statusline"]         = "statusline $fg"
            v["separator"]          = "separator  $bg"
            v["focused_workspace"]  = "focused_workspace  $c0       $c11      $c15"
            v["active_workspace"]   = "active_workspace   $c11      $c8       $c15"
            v["inactive_workspace"] = "inactive_workspace $c0       $c8       $c15"
            v["urgent_workspace"]   = "urgent_workspace   $c1       $c15      $c0"
            v["binding_mode"]       = "binding_mode       $bg       $bg       $fg"
        }
        /(bar_status|bar_mode) workspace color/ { inblock = 1; print; next }
        inblock && /^[[:space:]]*}/ { inblock = 0; print; next }
        inblock {
            line = $0
            sub(/^[[:space:]]*#?[[:space:]]*/, "", line)
            split(line, f, /[[:space:]]+/)
            if (f[1] in v) { print "        " p v[f[1]]; next }
        }
        /bumblebee-status theme/ { print "        -t " theme " # bumblebee-status theme"; next }
        { print }
    ' "$BAR_CONFIG" > "$tmp" && cat "$tmp" > "$BAR_CONFIG"
    rm -f -- "$tmp"
}

bar_decoration () {
    case $1 in
        "i3")
            apply_bar_colors '#' default
            ;;
        "pywal")
            apply_bar_colors '' i3bar-wal
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
bar_decoration "$1"
