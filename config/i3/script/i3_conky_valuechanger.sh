#!/usr/bin/env bash

# NOTE for awk
# /*color/ works for gawk but not mawk, therefore we use /.*color/ here
# -- In ubuntu system, default awk is mawk (less tolerative for regex)
# -- In fedora system, default awk is gawk (more tolerative for regex)

# Third argument [color0~color15/opac0~opac100]
# Read item color (content) from wal Xresources based on input
value_picker () {
    case $1 in
        color0)
            OUTPUT_VALUE="$(awk '$1~/.*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color1)
            OUTPUT_VALUE="$(awk '$1~/.*color1:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color2)
            OUTPUT_VALUE="$(awk '$1~/.*color2:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color3)
            OUTPUT_VALUE="$(awk '$1~/.*color3:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color4)
            OUTPUT_VALUE="$(awk '$1~/.*color4:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color5)
            OUTPUT_VALUE="$(awk '$1~/.*color5:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color6)
            OUTPUT_VALUE="$(awk '$1~/.*color6:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color7)
            OUTPUT_VALUE="$(awk '$1~/.*color7:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color8)
            OUTPUT_VALUE="$(awk '$1~/.*color8:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color9)
            OUTPUT_VALUE="$(awk '$1~/.*color9:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color10)
            OUTPUT_VALUE="$(awk '$1~/.*color10:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color11)
            OUTPUT_VALUE="$(awk '$1~/.*color11:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color12)
            OUTPUT_VALUE="$(awk '$1~/.*color12:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color13)
            OUTPUT_VALUE="$(awk '$1~/.*color13:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color14)
            OUTPUT_VALUE="$(awk '$1~/.*color14:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
            ;;
        color15)
            OUTPUT_VALUE="$(awk '$1~/.*color15:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
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
        *)
            OUTPUT_VALUE=$1
            ;;
    esac
}

change_conky_value () {
    # Assign default item / title color
    DEFAULT_COLOR="$(awk '$1~/.*color11:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
    DEFAULT_TEXT_COLOR="$(awk '$1~/.*color15:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
    DEFAULT_ITEM_COLOR="$(awk '$1~/.*color11:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
    DEFAULT_TITLE_COLOR="$(awk '$1~/.*color13:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
    DEFAULT_BG_COLOR="$(awk '$1~/.*color0:/ {print substr($2,2,7)}' $HOME/.cache/wal/colors.Xresources | awk NR==1)"
    DEFAULT_BG_OPAC=$(awk '$0~/default_conky_opacity/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_POS_SYSTEM=$(awk '$0~/default_conky_system_alignment/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_POS_BINDKEY=$(awk '$0~/default_conky_bindkey_alignment/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_GAP_Y=$(awk '$0~/default_conky_gap_y/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_BAR_MODE=$(awk '$0~/default_i3bar_mode/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    DEFAULT_BAR_POS=$(awk '$0~/default_i3bar_position/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
    # Replace color in conky configuration file
    case $1 in
        # Conky for system
        "system")
            CONFIGS[0]="$HOME/.config/conky/full/conky_config_system"
            CONFIGS[1]="$HOME/.config/conky/light/conky_config_system"
            CONFIGS[2]="$HOME/.config/conky/minimal/conky_config_system"
            for config in ${CONFIGS[@]}; do
                COL_DEFAULT_COLOR=$(awk '$0~/default_color/ {print NR}' $config | awk 'NR==1')
                COL_TEXT_COLOR=$(awk '$0~/color1/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_ITEM=$(awk '$0~/color2/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_TITLE=$(awk '$0~/color3/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_BG=$(awk '$0~/own_window_colour/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_BG_OPAC=$(awk '$0~/own_window_argb_value/ {print NR}' $config | awk 'NR==1')
                COL_POS=$(awk '$0~/alignment/ {print NR}' $config | awk 'NR==1')
                COL_GAP_Y=$(awk '$0~/gap_y/ {print NR}' $config | awk 'NR==1')
                case $2 in
                    "default")
                        sed -i "$COL_DEFAULT_COLOR s/.*/\tdefault_color \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "text")
                        sed -i "$COL_TEXT_COLOR s/.*/\tcolor1 \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "item")
                        sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "title")
                        sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "background")
                        sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "bg_opacity")
                        sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $OUTPUT_VALUE,/" "$config"
                        ;;
                    "alignment")
                        sed -i "$COL_POS s/.*/\talignment \= \'$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "gap_y")
                        sed -i "$COL_GAP_Y s/.*/\tgap_y \= $OUTPUT_VALUE,/" "$config"
                        ;;
                    *)
                        sed -i "$COL_DEFAULT_COLOR s/.*/\tdefault_color \= \'\#$DEFAULT_COLOR\\',/" "$config"
                        sed -i "$COL_TEXT_COLOR s/.*/\tcolor1 \= \'\#$DEFAULT_TEXT_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$DEFAULT_ITEM_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$DEFAULT_TITLE_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$DEFAULT_BG_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $DEFAULT_BG_OPAC,/" "$config"
                        sed -i "$COL_POS s/.*/\talignment \= \'$DEFAULT_POS_SYSTEM\\',/" "$config"
                        # Gap-Y
                        DEFAULT_GAP_Y_SYSTEM=$DEFAULT_GAP_Y
                        if [[ $DEFAULT_POS_SYSTEM == *$DEFAULT_BAR_POS* ]] && [[ $DEFAULT_BAR_MODE == "dock" ]]; then
                            DEFAULT_GAP_Y_SYSTEM=$(expr $DEFAULT_BAR_HEIGHT + $DEFAULT_GAP_Y)
                        fi
                        sed -i "$COL_GAP_Y s/.*/\tgap_y \= ${DEFAULT_GAP_Y_SYSTEM},/" "$config"
                        ;;
                esac
            done
            ;;
        # Conky for bindkey
        "bindkey")
            CONFIGS[0]="$HOME/.config/conky/full/conky_config_bindkey"
            CONFIGS[1]="$HOME/.config/conky/light/conky_config_bindkey"
            CONFIGS[2]="$HOME/.config/conky/minimal/conky_config_bindkey"
            for config in ${CONFIGS[@]}; do
                COL_DEFAULT_COLOR=$(awk '$0~/default_color/ {print NR}' $config | awk 'NR==1')
                COL_TEXT_COLOR=$(awk '$0~/color1/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_ITEM=$(awk '$0~/color2/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_TITLE=$(awk '$0~/color3/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_BG=$(awk '$0~/own_window_colour/ {print NR}' $config | awk 'NR==1')
                COL_COLOR_BG_OPAC=$(awk '$0~/own_window_argb_value/ {print NR}' $config | awk 'NR==1')
                COL_POS=$(awk '$0~/alignment/ {print NR}' $config | awk 'NR==1')
                COL_GAP_Y=$(awk '$0~/gap_y/ {print NR}' $config | awk 'NR==1')
                case $2 in
                    "default")
                        sed -i "$COL_DEFAULT_COLOR s/.*/\tdefault_color \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "text")
                        sed -i "$COL_TEXT_COLOR s/.*/\tcolor1 \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "item")
                        sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "title")
                        sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "background")
                        sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "bg_opacity")
                        sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $OUTPUT_VALUE,/" "$config"
                        ;;
                    "alignment")
                        sed -i "$COL_POS s/.*/\talignment \= \'$OUTPUT_VALUE\\',/" "$config"
                        ;;
                    "gap_y")
                        sed -i "$COL_GAP_Y s/.*/\tgap_y \= $OUTPUT_VALUE,/" "$config"
                        ;;
                    *)
                        sed -i "$COL_DEFAULT_COLOR s/.*/\tdefault_color \= \'\#$DEFAULT_COLOR\\',/" "$config"
                        sed -i "$COL_TEXT_COLOR s/.*/\tcolor1 \= \'\#$DEFAULT_TEXT_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_ITEM s/.*/\tcolor2 \= \'\#$DEFAULT_ITEM_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_TITLE s/.*/\tcolor3 \= \'\#$DEFAULT_TITLE_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_BG s/.*/\town_window_colour \= \'\#$DEFAULT_BG_COLOR\\',/" "$config"
                        sed -i "$COL_COLOR_BG_OPAC s/.*/\town_window_argb_value \= $DEFAULT_BG_OPAC,/" "$config"
                        sed -i "$COL_POS s/.*/\talignment \= \'$DEFAULT_POS_BINDKEY\\',/" "$config"
                        # Gap-Y
                        DEFAULT_GAP_Y_BINDKEY=$DEFAULT_GAP_Y
                        if [[ $DEFAULT_POS_BINDKEY == *$DEFAULT_BAR_POS* ]] && [[ $DEFAULT_BAR_MODE == "dock" ]]; then
                            DEFAULT_GAP_Y_BINDKEY=$(expr $DEFAULT_BAR_HEIGHT + $DEFAULT_GAP_Y)
                        fi
                        sed -i "$COL_GAP_Y s/.*/\tgap_y \= ${DEFAULT_GAP_Y_BINDKEY},/" "$config"
                        ;;
                esac
            done
            ;;
    esac
}

# Main
value_picker $3
change_conky_value $1 $2
