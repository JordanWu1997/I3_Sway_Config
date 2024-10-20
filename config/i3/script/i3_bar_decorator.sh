#!/usr/bin/env bash

BAR_CONFIG="$HOME/.config/i3/config.d/i3_bar.config"

# Bar1
COL_BAR1_1=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 2)
COL_BAR1_2=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 3)
COL_BAR1_3=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 4)
COL_BAR1_4=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 6)
COL_BAR1_5=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 7)
COL_BAR1_6=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 8)
COL_BAR1_7=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 9)
COL_BAR1_8=$(expr $(awk '$0~/bar_status workspace color/{print NR}' $BAR_CONFIG) + 10)
# Bumblebee status
COL_BUMBLEBEE_THEME=$(awk '$0~/bumblebee-status theme/{print NR}' $BAR_CONFIG)
# Bar2
COL_BAR2_1=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 2)
COL_BAR2_2=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 3)
COL_BAR2_3=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 4)
COL_BAR2_4=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 6)
COL_BAR2_5=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 7)
COL_BAR2_6=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 8)
COL_BAR2_7=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 9)
COL_BAR2_8=$(expr $(awk '$0~/bar_mode workspace color/{print NR}' $BAR_CONFIG) + 10)

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_bar_decorator.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [i3]: i3 default colorscheme"
    echo "  [pywal]: pywal colorscheme"
}

bar_decoration () {
    case $1 in
        "i3")
            # Bar_base
            sed -i "$COL_BAR1_1 s/.*/        #background \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_2 s/.*/        #statusline \$fg/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_3 s/.*/        #separator  \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_4 s/.*/        #focused_workspace  \$c0       \$c11      \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_5 s/.*/        #active_workspace   \$c11      \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_6 s/.*/        #inactive_workspace \$c0       \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_7 s/.*/        #urgent_workspace   \$c1       \$c15      \$c0/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_8 s/.*/        #binding_mode       \$bg       \$bg       \$fg/" "$BAR_CONFIG"
            # Bar_overlay
            sed -i "$COL_BAR2_1 s/.*/        #background \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_2 s/.*/        #statusline \$fg/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_3 s/.*/        #separator  \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_4 s/.*/        #focused_workspace  \$c0       \$c11      \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_5 s/.*/        #active_workspace   \$c11      \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_6 s/.*/        #inactive_workspace \$c0       \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_7 s/.*/        #urgent_workspace   \$c1       \$c15      \$c0/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_8 s/.*/        #binding_mode       \$bg       \$bg       \$fg/" "$BAR_CONFIG"
            # Bumblebee status (Bar_base)
            sed -i "$COL_BUMBLEBEE_THEME s/.*/        -t default # bumblebee-status theme/" "$BAR_CONFIG"
            ;;
        "pywal")
            # Bar_base
            sed -i "$COL_BAR1_1 s/.*/        background \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_2 s/.*/        statusline \$fg/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_3 s/.*/        separator  \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_4 s/.*/        focused_workspace  \$c0       \$c11      \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_5 s/.*/        active_workspace   \$c11      \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_6 s/.*/        inactive_workspace \$c0       \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_7 s/.*/        urgent_workspace   \$c1       \$c15      \$c0/" "$BAR_CONFIG"
            sed -i "$COL_BAR1_8 s/.*/        binding_mode       \$bg       \$bg       \$fg/" "$BAR_CONFIG"
            # Bar_overlay
            sed -i "$COL_BAR2_1 s/.*/        background \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_2 s/.*/        statusline \$fg/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_3 s/.*/        separator  \$bg/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_4 s/.*/        focused_workspace  \$c0       \$c11      \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_5 s/.*/        active_workspace   \$c11      \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_6 s/.*/        inactive_workspace \$c0       \$c8       \$c15/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_7 s/.*/        urgent_workspace   \$c1       \$c15      \$c0/" "$BAR_CONFIG"
            sed -i "$COL_BAR2_8 s/.*/        binding_mode       \$bg       \$bg       \$fg/" "$BAR_CONFIG"
            # Bumblebee status (Bar_base)
            sed -i "$COL_BUMBLEBEE_THEME s/.*/        -t i3bar-wal # bumblebee-status theme/" "$BAR_CONFIG"
            #
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    i3-msg reload
}

# Main
bar_decoration $1
