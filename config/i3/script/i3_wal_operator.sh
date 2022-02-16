#!/usr/bin/env bash

COL_WAL=$(expr $(awk '$0~/Startup-Wal/{print NR}' ~/.config/i3/config) + 1)
case $1 in
    "enable_16_color")
        awk 'NR==2 {print $4}' "$HOME/.fehbg" | xargs -I {} wal -i {}
        sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
        ;;
    "enable_9_color")
        awk 'NR==2 {print $4}' "$HOME/.fehbg" | xargs -I {} wal -i {} --nine
        sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id wal \-\-nine \-i \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
        ;;
    "disable")
        rm -rf "$HOME/.cache/wal"
        sed -i "$COL_WAL s/.*/exec \-\-no\-startup\-id feh \-\-bg\-scale \$HOME\/\.config\/i3\/share\/default_wallpaper/" "$HOME/.config/i3/config"
        ;;
esac
