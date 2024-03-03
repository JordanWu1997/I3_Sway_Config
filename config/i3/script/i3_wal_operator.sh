#!/usr/bin/env bash

COL_WAL=$(expr $(awk '$0~/Startup-Wal/{print NR}' ~/.config/i3/config) + 1)
ICON="$HOME/.config/i3/share/64x64/paint_palette.png"

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
    case $1 in
        "enable_16_color_wal")
            # Enable 16 color
            awk -F\' 'NR==2 {print $2}' "$HOME/.fehbg" | xargs -I {} wal -i {}
            # Set default pywal
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
            notify-send -u low "Theme Mode" "Auto-theme with pywal (16-color)" --icon=${ICON}
            ;;
        "enable_9_color_wal")
            # Enable 9 color
            awk -F\' 'NR==2 {print $2}' "$HOME/.fehbg" | xargs -I {} wal -i {} --nine
            # Set default pywal
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-\-nine \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
            notify-send -u low "Theme Mode" "Auto-theme with pywal (9-color)" --icon=${ICON}
            ;;
        "disable_wal")
            # Remove pywal result
            rm -rf "$HOME/.cache/wal"
            # Set default wallpaper only
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id feh \-\-bg\-scale \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
            notify-send -u low "Theme Mode" "Disable auto-theme (kill pywal and startup pywal)" --icon=${ICON}
            ;;
        "disable_wal_and_apply_template")
            # Apply templates
            $I3_SCRIPT/i3_apply_template_theme.sh
            # Set default wallpaper only
            sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id feh \-\-bg\-scale \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
            notify-send -u low "Theme Mode" "Apply template theme and disable startup pywal" --icon=${ICON}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    i3-msg reload
}

# Main
wal_operation $1
