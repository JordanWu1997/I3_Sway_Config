#!/usr/bin/env bash

ICON="$HOME/.config/i3/share/64x64/reload.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_reload_operator.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [all]: reload conky, dunct, i3bar, zathura and vis"
    echo "  [conky]: reload conky (system monitor)"
    echo "  [dunst]: reload dunst (notifier)"
    echo "  [i3bar]: reload i3bari (status bar)"
    echo "  [zathura]: reload zathura (PDF viewer)"
    echo "  [vis]: reload vis (cli-visualizer) "
    echo "  [Xresource]: reload X resources"
    echo "  [xsslock]: restart xsslock (xwindow wrapper for i3lock)"
}

reload_conky () {
    # Conky (system monitor & shortcut table)
    "$I3_SCRIPT/i3_conky_valuechanger.sh" system all && sleep 1
    "$I3_SCRIPT/i3_conky_valuechanger.sh" bindkey all && sleep 1
    notify-send -u low "Reload Mode" "Reload conky (system monitor)" --icon="${ICON}"
}

reload_i3bar () {
    "$I3_SCRIPT/i3_bar_operator.sh" bar_reload
    notify-send -u low "Reload Mode" "Reload i3bar (status bar)" --icon="${ICON}"
}

reload_dunst () {
    # Dunst (notifier)
    "$I3_SCRIPT/i3_dunst_operator.sh" reload_all
    notify-send -u low "Reload Mode" "Reload dunst (notifier)" --icon="${ICON}"
}

reload_vis () {
    # Vis (visualizer)
    "$I3_SCRIPT/i3_vis_colorchanger.sh"
    notify-send -u low "Reload Mode" "Reload vis (cli-equalizer)" --icon="${ICON}"
}

reload_zathura () {
    # Zathura (PDF viewer)
    zathura-pywal -a 0.7
    notify-send -u low "Reload Mode" "Reload zathura (PDF viewer)" --icon="${ICON}"
}

reload_Xresources  () {
    xrdb "$HOME/.Xresources"
    notify-send -u low "Reload Mode" "Reload Xresources (~/.Xresouces)" --icon="${ICON}"

}

reload_xsslock () {
    "$I3_SCRIPT/i3_xsslock_operator.sh" current_desktop
    notify-send -u low "Reload Mode" "Reload xsslock (session lock)" --icon="${ICON}"
}

# Main reload pipline
reload_pipeline () {
    case $1 in
        'all')
            reload_dunst
            reload_conky
            reload_i3bar
            reload_zathura
            reload_vis
            ;;
        'conky')
            reload_conky
            ;;
        'dunst')
            reload_dunst
            ;;
        'i3bar')
            reload_i3_bar
            ;;
        'zathura')
            reload_zathura
            ;;
        'vis')
            reload_vis
            ;;
        'xsslock')
            reload_xsslock
            ;;
        'Xresources')
            reload_Xresources
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
reload_pipeline "$@"
