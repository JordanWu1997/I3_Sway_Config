#!/usr/bin/env bash

# Default color (color1), primary color (color2) in conky configuration
if [ -z $1 ]; then
    # Wrong input, send error message
    echo "Wrong input, color not change. Try system or rofi as input"
elif [ $1 == "system" ]; then
    col_color_text=$(awk '$0~/default_color/ {print NR}' $HOME/.config/conky/conky_config_system | awk 'NR==1')
    col_color_item=$(awk '$0~/color2/ {print NR}' $HOME/.config/conky/conky_config_system | awk 'NR==1')
    col_color_title=$(awk '$0~/color3/ {print NR}' $HOME/.config/conky/conky_config_system | awk 'NR==1')
elif [ $1 == "hotkey" ]; then
    col_color_text=$(awk '$0~/default_color/ {print NR}' $HOME/.config/conky/conky_config_hotkey | awk 'NR==1')
    col_color_item=$(awk '$0~/color2/ {print NR}' $HOME/.config/conky/conky_config_hotkey | awk 'NR==1')
    col_color_title=$(awk '$0~/color3/ {print NR}' $HOME/.config/conky/conky_config_hotkey | awk 'NR==1')
fi

# Read text color from wal Xresources
color_text="$(awk '$1~/*color15/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"

# Read item color (content) from wal Xresources based on input
input_color=$3
case $input_color in
    color0)
        output_color="$(awk '$1~/*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color1)
        output_color="$(awk '$1~/*color1:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color2)
        output_color="$(awk '$1~/*color2:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color3)
        output_color="$(awk '$1~/*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color4)
        output_color="$(awk '$1~/*color4:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color5)
        output_color="$(awk '$1~/*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color6)
        output_color="$(awk '$1~/*color6:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color7)
        output_color="$(awk '$1~/*color7:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
esac

# Assign default item / title color
default_item_color="$(awk '$1~/*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
default_title_color="$(awk '$1~/*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"

# Replace color in conky configuration file
if [ -z $1 ]; then
    # Wrong input, send error message
    echo "Wrong input, color not change. Try system or rofi as input"
elif [ "$1" == "system" ]; then
    # Conky for system
    sed -i "$col_color_text s/.*/\tdefault_color \= \'\#$color_text\\',/" "$HOME/.config/conky/conky_config_system"
    if [ "$2" == "item" ]; then
        sed -i "$col_color_item s/.*/\tcolor2 \= \'\#$output_color\\',/" "$HOME/.config/conky/conky_config_system"
    elif [ "$2" == "title" ]; then
        sed -i "$col_color_title s/.*/\tcolor3 \= \'\#$output_color\\',/" "$HOME/.config/conky/conky_config_system"
    # Default color
    else
        sed -i "$col_color_item s/.*/\tcolor2 \= \'\#$default_item_color\\',/" "$HOME/.config/conky/conky_config_system"
        sed -i "$col_color_title s/.*/\tcolor3 \= \'\#$default_title_color\\',/" "$HOME/.config/conky/conky_config_system"
    fi
elif [ "$1" == "hotkey" ]; then
    # Conky for hotkey
    sed -i "$col_color_text s/.*/\tdefault_color \= \'\#$color_text\\',/" "$HOME/.config/conky/conky_config_hotkey"
    if [ "$2" == "item" ]; then
        sed -i "$col_color_item s/.*/\tcolor2 \= \'\#$output_color\\',/" "$HOME/.config/conky/conky_config_hotkey"
    elif [ "$2" == "title" ]; then
        sed -i "$col_color_title s/.*/\tcolor3 \= \'\#$output_color\\',/" "$HOME/.config/conky/conky_config_hotkey"
    # Default color
    else
        sed -i "$col_color_item s/.*/\tcolor2 \= \'\#$default_item_color\\',/" "$HOME/.config/conky/conky_config_hotkey"
        sed -i "$col_color_title s/.*/\tcolor3 \= \'\#$default_title_color\\',/" "$HOME/.config/conky/conky_config_hotkey"
    fi
else
    echo $0
fi
