#!/usr/bin/env bash

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Datetime    : 2025-01-08 15:00:36
# Description :
###########################################################

# i3 (font)
grep -n -m 1 -w '^set $default_font' $HOME/.config/i3/config
grep -n -m 1 -w '^set $default_i3bar_fontsize' $HOME/.config/i3/config
grep -n -m 1 -w '^set $default_i3bar_height' $HOME/.config/i3/config
grep -n -m 1 -w '^set $default_titlebar_fontsize' $HOME/.config/i3/config

# kitty (font)
grep -n -m 1 -w '^font_family' $HOME/.config/kitty/kitty_common.conf
grep -n -m 1 -w '^font_size' $HOME/.config/kitty/kitty_common.conf

# rofi (font + fontsize)
for rofi_file in $HOME/.config/rofi/*.rasi; do
    grep -n -m 1 -w ' font: ' ${rofi_file}
done

# dunst (font + fontsize)
for dunst_file in $HOME/.config/dunst/dunst*; do
    grep -n -m 1 -w ' font: ' ${rofi_file}
done

# Ignored for now: conky (font + fontsize), mpv (font)
