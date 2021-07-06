#!/usr/bin/bash

# Default color (color1), primary color (color2) in conky configuration
col_color1=32
col_color2=33

# Read font color from wal Xresources
color1="$(awk '$1~/*color15/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"

# Read font color (content) from wal Xresources based on input
input_color=$2
case $input_color in
    color0)
        color2="$(awk '$1~/*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        echo $color2
        ;;
    color1)
        color2="$(awk '$1~/*color1:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        echo $color2
        ;;
    color2)
        color2="$(awk '$1~/*color2:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color3)
        color2="$(awk '$1~/*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color4)
        color2="$(awk '$1~/*color4:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color5)
        color2="$(awk '$1~/*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color6)
        color2="$(awk '$1~/*color6:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color7)
        color2="$(awk '$1~/*color7:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
esac

# Replace color in conky configuration file
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
