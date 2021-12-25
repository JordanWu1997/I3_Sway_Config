#!/usr/bin/env bash

# Default color (color1), primary color (color2) in conky configuration
case $1 in
    "system")
        COL_COLOR_TEXT=$(awk '$0~/default_color/ {print NR}' $HOME/.config/conky/conky_config_system | awk 'NR==1')
        COL_COLOR_ITEM=$(awk '$0~/color2/ {print NR}' $HOME/.config/conky/conky_config_system | awk 'NR==1')
        COL_COLOR_TITLE=$(awk '$0~/color3/ {print NR}' $HOME/.config/conky/conky_config_system | awk 'NR==1')
        ;;
    "hotkey")
        COL_COLOR_TEXT=$(awk '$0~/default_color/ {print NR}' $HOME/.config/conky/conky_config_hotkey | awk 'NR==1')
        COL_COLOR_ITEM=$(awk '$0~/color2/ {print NR}' $HOME/.config/conky/conky_config_hotkey | awk 'NR==1')
        COL_COLOR_TITLE=$(awk '$0~/color3/ {print NR}' $HOME/.config/conky/conky_config_hotkey | awk 'NR==1')
        ;;
    # Wrong input, send error message
    *)
        echo "Wrong input, color not change. Try system or rofi as input"
esac

# Read text color from wal Xresources
COLOR_TEXT="$(awk '$1~/*color15/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"

# Read item color (content) from wal Xresources based on input
INPUT_COLOR=$3
case $INPUT_COLOR in
    color0)
        OUTPUT_COLOR="$(awk '$1~/*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color1)
        OUTPUT_COLOR="$(awk '$1~/*color1:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color2)
        OUTPUT_COLOR="$(awk '$1~/*color2:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color3)
        OUTPUT_COLOR="$(awk '$1~/*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color4)
        OUTPUT_COLOR="$(awk '$1~/*color4:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color5)
        OUTPUT_COLOR="$(awk '$1~/*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color6)
        OUTPUT_COLOR="$(awk '$1~/*color6:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color7)
        OUTPUT_COLOR="$(awk '$1~/*color7:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
esac

# Assign default item / title color
DEFAULT_ITEM_COLOR="$(awk '$1~/*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
DEFAULT_TITLE_COLOR="$(awk '$1~/*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"

# Replace color in conky configuration file
case $1 in
    # Conky for system
    "system")
        sed -i "$COL_COLOR_TEXT s/.*/\tdefault_color \= \'\#$COLOR_TEXT\\',/" "$HOME/.config/conky/conky_config_system"
        if [ "$2" == "item" ]; then
            sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$OUTPUT_COLOR\\',/" "$HOME/.config/conky/conky_config_system"
        elif [ "$2" == "title" ]; then
            sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$OUTPUT_COLOR\\',/" "$HOME/.config/conky/conky_config_system"
        # Default color
        else
            sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$DEFAULT_ITEM_COLOR\\',/" "$HOME/.config/conky/conky_config_system"
            sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$DEFAULT_TITLE_COLOR\\',/" "$HOME/.config/conky/conky_config_system"
        fi
        ;;
    # Conky for hotkey
    "hotkey")
        sed -i "$COL_COLOR_TEXT s/.*/\tdefault_color \= \'\#$COLOR_TEXT\\',/" "$HOME/.config/conky/conky_config_hotkey"
        if [ "$2" == "item" ]; then
            sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$OUTPUT_COLOR\\',/" "$HOME/.config/conky/conky_config_hotkey"
        elif [ "$2" == "title" ]; then
            sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$OUTPUT_COLOR\\',/" "$HOME/.config/conky/conky_config_hotkey"
        # Default color
        else
            sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$DEFAULT_ITEM_COLOR\\',/" "$HOME/.config/conky/conky_config_hotkey"
            sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$DEFAULT_TITLE_COLOR\\',/" "$HOME/.config/conky/conky_config_hotkey"
        fi
        ;;
    # Wrong input, send error message
    *)
        echo "Wrong input $0"
        echo "Color not change. Try system or rofi as input"
esac
