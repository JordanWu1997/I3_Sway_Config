#!/usr/bin/env bash

COL_WAL=$(expr $(awk '$0~/Startup-Wal/{print NR}' ~/.config/i3/config) + 1)

case $1 in
    "enable_16_color")
        # Enable 16 color
        awk 'NR==2 {print $4}' "$HOME/.fehbg" | xargs -I {} wal -i {}
        # Set default pywal
        sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
        ;;
    "enable_9_color")
        # Enable 9 color
        awk 'NR==2 {print $4}' "$HOME/.fehbg" | xargs -I {} wal -i {} --nine
        # Set default pywal
        sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-\-nine \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
        ;;
    "disable")
        # Remove pywal result
        rm -rf "$HOME/.cache/wal"
        # Set default wallpaper only
        sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id feh \-\-bg\-scale \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
        ;;
esac

i3-msg reload
