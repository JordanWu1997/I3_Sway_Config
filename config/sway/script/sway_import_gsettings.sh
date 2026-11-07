#!/usr/bin/env bash
# ~/.config/sway/script/sway_import_gsettings.sh
# Native GTK applications on Wayland do not read ~/.gtkrc-2.0, Xresources or xsettingsd;
# they read gsettings (org.gnome.desktop.interface). Copy the GTK 3 settings.ini values
# into gsettings so native and XWayland GTK apps share the same theme, icons, font, cursor.
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
[ -f "$CONFIG" ] || exit 0
command -v gsettings >/dev/null || exit 0

get() { sed -n "s/^\s*$1\s*=\s*//p" "$CONFIG" | head -n1; }
SCHEMA=org.gnome.desktop.interface
v=$(get gtk-theme-name);        [ -n "$v" ] && gsettings set $SCHEMA gtk-theme "$v"
v=$(get gtk-icon-theme-name);   [ -n "$v" ] && gsettings set $SCHEMA icon-theme "$v"
v=$(get gtk-cursor-theme-name); [ -n "$v" ] && gsettings set $SCHEMA cursor-theme "$v"
v=$(get gtk-cursor-theme-size); [ -n "$v" ] && gsettings set $SCHEMA cursor-size "$v"
v=$(get gtk-font-name);         [ -n "$v" ] && gsettings set $SCHEMA font-name "$v"
exit 0
