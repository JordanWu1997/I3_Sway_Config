#!/usr/bin/env bash

# Third argument [color0~color15/opac0~opac100]
# Read item color (content) from wal Xresources based on input
case $3 in
    color0)
        OUTPUT_VALUE="$(awk '$1~/*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color1)
        OUTPUT_VALUE="$(awk '$1~/*color1:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color2)
        OUTPUT_VALUE="$(awk '$1~/*color2:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color3)
        OUTPUT_VALUE="$(awk '$1~/*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color4)
        OUTPUT_VALUE="$(awk '$1~/*color4:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color5)
        OUTPUT_VALUE="$(awk '$1~/*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color6)
        OUTPUT_VALUE="$(awk '$1~/*color6:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color7)
        OUTPUT_VALUE="$(awk '$1~/*color7:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color8)
        OUTPUT_VALUE="$(awk '$1~/*color8:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color9)
        OUTPUT_VALUE="$(awk '$1~/*color9:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color10)
        OUTPUT_VALUE="$(awk '$1~/*color10:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color11)
        OUTPUT_VALUE="$(awk '$1~/*color11:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color12)
        OUTPUT_VALUE="$(awk '$1~/*color12:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color13)
        OUTPUT_VALUE="$(awk '$1~/*color13:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color14)
        OUTPUT_VALUE="$(awk '$1~/*color14:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    color15)
        OUTPUT_VALUE="$(awk '$1~/*color15:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
        ;;
    opac0)
        OUTPUT_VALUE=0
        ;;
    opac25)
        OUTPUT_VALUE=64
        ;;
    opac50)
        OUTPUT_VALUE=128
        ;;
    opac75)
        OUTPUT_VALUE=192
        ;;
    opac100)
        OUTPUT_VALUE=256
        ;;
esac

# Assign default item / title color
DEFAULT_ITEM_COLOR="$(awk '$1~/*color11:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
DEFAULT_TITLE_COLOR="$(awk '$1~/*color13:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
DEFAULT_BG_COLOR="$(awk '$1~/*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
DEFAULT_COLOR_TEXT="$(awk '$1~/*color15/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources)"
DEFAULT_BG_OPAC=128

# Replace color in conky configuration file
case $1 in
    # Conky for system
    "system")
        CONFIG="$HOME/.config/conky/conky_config_system"
        COL_COLOR_TEXT=$(awk '$0~/default_color/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_ITEM=$(awk '$0~/color2/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_TITLE=$(awk '$0~/color3/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_BG=$(awk '$0~/own_window_colour/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_BG_OPAC=$(awk '$0~/own_window_argb_value/ {print NR}' $CONFIG | awk 'NR==1')
        case $2 in
            "text")
                sed -i "$COL_COLOR_TEXT s/.*/\tdefault_color \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "item")
                sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "title")
                sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "background")
                sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "bg_opacity")
                sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $OUTPUT_VALUE,/" "$CONFIG"
                ;;
            *)
                sed -i "$COL_COLOR_TEXT s/.*/\tdefault_color \= \'\#$DEFAULT_COLOR_TEXT\\',/" "$CONFIG"
                sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$DEFAULT_ITEM_COLOR\\',/" "$CONFIG"
                sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$DEFAULT_TITLE_COLOR\\',/" "$CONFIG"
                sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$DEFAULT_BG_COLOR\\',/" "$CONFIG"
                sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $DEFAULT_BG_OPAC,/" "$CONFIG"
                ;;
        esac
        ;;
    # Conky for bindkey
    "bindkey")
        CONFIG="$HOME/.config/conky/conky_config_bindkey"
        COL_COLOR_TEXT=$(awk '$0~/default_color/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_ITEM=$(awk '$0~/color2/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_TITLE=$(awk '$0~/color3/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_BG=$(awk '$0~/own_window_colour/ {print NR}' $CONFIG | awk 'NR==1')
        COL_COLOR_BG_OPAC=$(awk '$0~/own_window_argb_value/ {print NR}' $CONFIG | awk 'NR==1')
        case $2 in
            "text")
                sed -i "$COL_COLOR_TEXT s/.*/\tdefault_color \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "item")
                sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "title")
                sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "background")
                sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$OUTPUT_VALUE\\',/" "$CONFIG"
                ;;
            "bg_opacity")
                sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $OUTPUT_VALUE,/" "$CONFIG"
                ;;
            *)
                sed -i "$COL_COLOR_TEXT s/.*/\tdefault_color \= \'\#$DEFAULT_COLOR_TEXT\\',/" "$CONFIG"
                sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$DEFAULT_ITEM_COLOR\\',/" "$CONFIG"
                sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$DEFAULT_TITLE_COLOR\\',/" "$CONFIG"
                sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$DEFAULT_BG_COLOR\\',/" "$CONFIG"
                sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $DEFAULT_BG_OPAC,/" "$CONFIG"
                ;;
        esac
        ;;
esac
