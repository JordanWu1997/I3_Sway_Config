#!/usr/bin/env bash

COL_WIN1=$(expr $(awk '$0~/Color Palette/{print NR}' ~/.config/i3/configs/i3_window.config) + 2)
COL_WIN2=$(expr $(awk '$0~/Color Palette/{print NR}' ~/.config/i3/configs/i3_window.config) + 3)
COL_WIN3=$(expr $(awk '$0~/Color Palette/{print NR}' ~/.config/i3/configs/i3_window.config) + 4)
COL_WIN4=$(expr $(awk '$0~/Color Palette/{print NR}' ~/.config/i3/configs/i3_window.config) + 5)
COL_WIN5=$(expr $(awk '$0~/Color Palette/{print NR}' ~/.config/i3/configs/i3_window.config) + 6)
COL_WIN6=$(expr $(awk '$0~/Color Palette/{print NR}' ~/.config/i3/configs/i3_window.config) + 7)

case $1 in
    "monochromic")
        # Set window decoration
        sed -i "$COL_WIN1 s/.*/client.focused          \$c5     \$c5     \$c15    \$c13    \$c13/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN2 s/.*/client.focused_inactive \$c1     \$c1     \$c7     \$c9     \$c9/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN3 s/.*/client.unfocused        \$c1     \$c1     \$c7     \$c1     \$c1/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN4 s/.*/client.urgent           \$c0     \$c15    \$c0     \$c15    \$c15/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN5 s/.*/client.placeholder      \$c1     \$c1     \$c15    \$c9     \$c9/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN6 s/.*/client.background               \$c0/" "$HOME/.config/i3/configs/i3_window.config"
        ;;
    "dirchromatic")
        # Set window decoration
        sed -i "$COL_WIN1 s/.*/client.focused          \$c13    \$c5     \$c15    \$c11    \$c13/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN2 s/.*/client.focused_inactive \$c9     \$c1     \$c7     \$c10    \$c9/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN3 s/.*/client.unfocused        \$c1     \$c1     \$c7     \$c12    \$c1/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN4 s/.*/client.urgent           \$c0     \$c15    \$c0     \$c15    \$c0/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN5 s/.*/client.placeholder      \$c1     \$c1     \$c15    \$c14    \$c1/" "$HOME/.config/i3/configs/i3_window.config"
        sed -i "$COL_WIN6 s/.*/client.background               \$c0/" "$HOME/.config/i3/configs/i3_window.config"
        ;;
esac

i3-msg reload
