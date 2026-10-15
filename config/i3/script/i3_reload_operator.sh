#!/usr/bin/env bash

ICON="$HOME/.config/i3/share/64x64/reload.png"

report_reload () {
    local label=$1 status=$2
    if (( status == 0 )); then
        notify-send -u low "Reload Mode" "$label" --icon="$ICON" || true
    else
        notify-send -u critical "Reload failed" "$label" --icon="$ICON" || true
    fi
    return "$status"
}

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
    echo "  [Xresources]: reload X resources"
    echo "  [xsslock]: restart xsslock (xwindow wrapper for i3lock)"
}

reload_conky () {
    # Conky (system monitor & shortcut table)
    if "$I3_SCRIPT/i3_conky_valuechanger.sh" system all && sleep 1 &&
        "$I3_SCRIPT/i3_conky_valuechanger.sh" bindkey all && sleep 1; then
        report_reload "Conky reloaded" 0
    else
        report_reload "Conky" 1
    fi
}

reload_i3bar () {
    if ! "$I3_SCRIPT/i3_bar_operator.sh" bar_reload; then
        report_reload "i3bar" 1
    fi
}

reload_dunst () {
    # Dunst (notifier)
    if ! "$I3_SCRIPT/i3_dunst_operator.sh" reload_all; then
        report_reload "Dunst" 1
    fi
}

reload_vis () {
    # Vis (visualizer)
    if "$I3_SCRIPT/i3_vis_colorchanger.sh"; then
        report_reload "Vis reloaded" 0
    else
        report_reload "Vis" 1
    fi
}

reload_zathura () {
    # Zathura (PDF viewer)
    if zathura-pywal -a 0.7; then
        report_reload "Zathura colors reloaded" 0
    else
        report_reload "Zathura" 1
    fi
}

reload_Xresources  () {
    if xrdb "$HOME/.Xresources"; then
        report_reload "Xresources reloaded" 0
    else
        report_reload "Xresources" 1
    fi

}

reload_xsslock () {
    if "$I3_SCRIPT/i3_xsslock_operator.sh" current_desktop; then
        report_reload "xss-lock restart requested" 0
    else
        report_reload "xss-lock" 1
    fi
}

# Main reload pipline
reload_pipeline () {
    case $1 in
        'all')
            local failed=0
            reload_dunst || failed=1
            reload_conky || failed=1
            reload_i3bar || failed=1
            reload_zathura || failed=1
            reload_vis || failed=1
            return "$failed"
            ;;
        'conky')
            reload_conky
            ;;
        'dunst')
            reload_dunst
            ;;
        'i3bar')
            reload_i3bar
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
