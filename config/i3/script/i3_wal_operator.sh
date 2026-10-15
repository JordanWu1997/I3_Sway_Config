#!/usr/bin/env bash

COL_WAL=$(expr $(awk '$0~/Startup-Wal/{print NR}' ~/.config/i3/config) + 1)
ICON="$HOME/.config/i3/share/64x64/paint_palette.png"

# Parse input arguments
OPERATION=$1
shift
WAL_OPTIONS=$@
WAL_OPTIONS_ESCAPE=$(echo $WAL_OPTIONS | sed 's/\-/\\\-/g')

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_wal_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_16_color_wal]: enable pywal and startup pywal in 16-color template"
    echo "  [enable_9_color_wal]: enable pywal and startup pywal in 9-color template"
    echo "  [disable_wal]: disable pywal and startup pywal"
    echo "  [disable_wal_and_apply_template]: disable startup pywal and apply theme template"
}

wal_operation () {
    local wallpaper
    case $OPERATION in
        "enable_16_color_wal")
            # Enable 16 color
            wallpaper=$(awk -F\' 'NR==2 {print $2}' "$HOME/.fehbg") || return 1
            [[ -f $wallpaper ]] || return 1
            wal -i "$wallpaper" ${WAL_OPTIONS} || return 1
            # Set default pywal
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal ${WAL_OPTIONS_ESCAPE} \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config" || return 1
            WAL_MESSAGE="Auto-theme with pywal (16-color) ${WAL_OPTIONS}"
            ;;
        "enable_9_color_wal")
            # Enable 9 color
            wallpaper=$(awk -F\' 'NR==2 {print $2}' "$HOME/.fehbg") || return 1
            [[ -f $wallpaper ]] || return 1
            wal -i "$wallpaper" --nine ${WAL_OPTIONS} || return 1
            # Set default pywal
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-\-nine ${WAL_OPTIONS_ESCAPE} \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config" || return 1
            WAL_MESSAGE="Auto-theme with pywal (9-color) ${WAL_OPTIONS}"
            ;;
        "disable_wal")
            # Remove pywal result
            rm -rf "$HOME/.cache/wal" || return 1
            # Set default wallpaper only
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id feh \-\-bg\-scale \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config" || return 1
            WAL_MESSAGE="Auto-theme disabled"
            ;;
        "disable_wal_and_apply_template")
            # Apply templates
            "$I3_SCRIPT/i3_apply_template_theme.sh" || return 1
            # Set default wallpaper only
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id feh \-\-bg\-scale \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config" || return 1
            WAL_MESSAGE="Template theme applied; startup pywal disabled"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            return 2
    esac
    i3-msg reload >/dev/null || return 1
}

# Main
if wal_operation "$OPERATION"; then
    notify-send -u low "Theme Mode" "$WAL_MESSAGE" --icon="$ICON" || true
else
    status=$?
    notify-send -u critical "Theme change failed" "$OPERATION" --icon="$ICON" || true
    exit "$status"
fi
