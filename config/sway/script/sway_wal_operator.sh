#!/usr/bin/env bash
# Ported from i3_wal_operator.sh for sway.
# Replaced X11 tools:
#   - current wallpaper from ~/.fehbg    -> sway_wallpaper_operator.sh state file (~/.cache/sway_wallpaper)
#   - wal -i (wal sets wallpaper w/ feh) -> wal -n -i (sway keeps the wallpaper via swaybg)
#   - Xresources/set_from_resource       -> pywal template ~/.cache/wal/colors-sway-i3 included by
#                                           ~/.config/sway/config, applied with swaymsg reload
#   - startup line after "Startup-Wal" in ~/.config/i3/config
#                                        -> same marker in ~/.config/sway/config
#   - i3_apply_template_theme.sh         -> sway_apply_template_theme.sh
# Subcommands and arguments are identical to the i3 version.
#
# Edited config line: the first non-comment line after the "# Startup-Wal" marker in
# ~/.config/sway/config, set to one of
#   exec wal [--nine] -n <wal options> -i $HOME/.config/i3/share/default_wallpaper
#   exec $SWAY_SCRIPT/sway_wallpaper_operator.sh feh restore_default quiet   (wal disabled;
#        $SWAY_SCRIPT is the sway config variable, i3 used: exec feh --bg-scale default_wallpaper)

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
SWAY_CONFIG="$HOME/.config/sway/config"
SWAY_WALLPAPER_STATE="${SWAY_WALLPAPER_STATE:-$HOME/.cache/sway_wallpaper}"
DEFAULT_WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
ICON="$HOME/.config/i3/share/64x64/paint_palette.png"

# Line to edit: first non-empty, non-comment line after the Startup-Wal marker
COL_WAL=$(awk '/Startup-Wal/ {found=1; next} found && $0 !~ /^[[:space:]]*(#|$)/ {print NR; exit}' "$SWAY_CONFIG" 2>/dev/null)

# Parse input arguments
OPERATION=$1
shift
WAL_OPTIONS=$*

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_wal_operator.sh [operations] [wal options]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_16_color_wal]: enable pywal and startup pywal in 16-color template"
    echo "  [enable_9_color_wal]: enable pywal and startup pywal in 9-color template"
    echo "  [disable_wal]: disable pywal and startup pywal"
    echo "  [disable_wal_and_apply_template]: disable startup pywal and apply theme template"
}

# Wallpaper currently shown by sway (see sway_wallpaper_operator.sh)
current_wallpaper () {
    local wallpaper
    [[ -r $SWAY_WALLPAPER_STATE ]] && wallpaper=$(head -n 1 "$SWAY_WALLPAPER_STATE")
    [[ -n $wallpaper && -f $wallpaper ]] || wallpaper=$DEFAULT_WALLPAPER
    printf '%s\n' "$wallpaper"
}

# Replace the startup line after the Startup-Wal marker
set_startup_line () {
    local line=$1 escaped
    [[ $COL_WAL =~ ^[0-9]+$ ]] || {
        echo "No 'Startup-Wal' marker (followed by a command line) in $SWAY_CONFIG" >&2
        return 1
    }
    escaped=$(printf '%s' "$line" | sed 's/[\/&]/\\&/g')
    sed -i "${COL_WAL} s/.*/${escaped}/" "$(readlink -f "$SWAY_CONFIG")"
}

wal_operation () {
    local wallpaper
    case $OPERATION in
        "enable_16_color_wal")
            # Enable 16 color
            wallpaper=$(current_wallpaper)
            [[ -f $wallpaper ]] || return 1
            wal -n -i "$wallpaper" ${WAL_OPTIONS} || return 1
            # Set default pywal
            set_startup_line "exec wal -n ${WAL_OPTIONS} -i \$HOME/.config/i3/share/default_wallpaper" || return 1
            WAL_MESSAGE="Auto-theme with pywal (16-color) ${WAL_OPTIONS}"
            ;;
        "enable_9_color_wal")
            # Enable 9 color
            wallpaper=$(current_wallpaper)
            [[ -f $wallpaper ]] || return 1
            wal -n -i "$wallpaper" --nine ${WAL_OPTIONS} || return 1
            # Set default pywal
            set_startup_line "exec wal --nine -n ${WAL_OPTIONS} -i \$HOME/.config/i3/share/default_wallpaper" || return 1
            WAL_MESSAGE="Auto-theme with pywal (9-color) ${WAL_OPTIONS}"
            ;;
        "disable_wal")
            # Remove pywal result (colors fall back to ~/.config/sway/share/colors-sway-fallback)
            rm -rf "$HOME/.cache/wal" || return 1
            # Set default wallpaper only
            set_startup_line "exec \$SWAY_SCRIPT/sway_wallpaper_operator.sh feh restore_default quiet" || return 1
            WAL_MESSAGE="Auto-theme disabled"
            ;;
        "disable_wal_and_apply_template")
            # Apply templates
            "$SWAY_SCRIPT/sway_apply_template_theme.sh" || return 1
            # Set default wallpaper only
            set_startup_line "exec \$SWAY_SCRIPT/sway_wallpaper_operator.sh feh restore_default quiet" || return 1
            WAL_MESSAGE="Template theme applied; startup pywal disabled"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            return 2
    esac
    # Re-read the config so ~/.cache/wal/colors-sway-i3 colors are applied
    swaymsg reload >/dev/null || return 1
    # A reload re-applies the config's "output * bg"; put the current wallpaper back
    [[ -x $SWAY_SCRIPT/sway_wallpaper_operator.sh ]] && "$SWAY_SCRIPT/sway_wallpaper_operator.sh" feh restore_last
    return 0
}

# Main
if wal_operation "$OPERATION"; then
    notify-send -u low "Theme Mode" "$WAL_MESSAGE" --icon="$ICON" || true
else
    status=$?
    notify-send -u critical "Theme change failed" "$OPERATION" --icon="$ICON" || true
    exit "$status"
fi
