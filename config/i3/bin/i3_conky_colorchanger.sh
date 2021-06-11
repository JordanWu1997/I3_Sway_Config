#!/usr/bin/bash

# Default color (color1), primary color (color2) in conky configuration
col_color1=32
col_color2=33

# Read color from wal Xresources
color1="$(awk '$1~/*color15/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
color2="$(awk '$1~/*color3/  {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"

if [ "$1" == "system" ]; then
    # Conky for system
    sed -i "$col_color1 s/.*/\tdefault_color \= \'\#$color1\\',/" "$HOME/.config/conky/conky_config_system"
    sed -i "$col_color2 s/.*/\tcolor2 \= \'\#$color2\\',/" "$HOME/.config/conky/conky_config_system"
elif [ "$1" == "hotkey" ]; then
    # Conky for hotkey
    sed -i "$col_color1 s/.*/\tdefault_color \= \'\#$color1\\',/" "$HOME/.config/conky/conky_config_hotkey"
    sed -i "$col_color2 s/.*/\tcolor2 \= \'\#$color2\\',/" "$HOME/.config/conky/conky_config_hotkey"
else
    # Wrong input, send error message
    echo "Wrong input, color not change. Try system or rofi as input"
fi
