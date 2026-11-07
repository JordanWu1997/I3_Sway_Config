#!/usr/bin/env bash
# ~/.config/sway/script/sway_reload_operator.sh
# Ported from i3_reload_operator.sh for sway.
# Replaced X11 tools / i3 parts:
#   - i3_conky_valuechanger.sh system/bindkey all -> sway_conky_monitor_display.sh default
#   - i3_bar_operator.sh bar_reload (i3bar)       -> sway_bar_operator.sh bar_reload (swaybar),
#                                                    `swaymsg reload` as fallback
#   - i3_xsslock_operator.sh current_desktop       -> sway_idle_operator.sh restart (swayidle)
#   - xrdb ~/.Xresources                           -> unchanged, XWayland apps only (needs DISPLAY)
# dunst, zathura-pywal and vis are toolkit independent (sway_* script preferred if present).

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"
export SWAY_SCRIPT I3_SCRIPT

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

# Prefer the sway port of a helper, fall back to the i3 one: script_path dunst_operator.sh
script_path () {
    if [[ -x $SWAY_SCRIPT/sway_$1 ]]; then
        printf '%s\n' "$SWAY_SCRIPT/sway_$1"
    else
        printf '%s\n' "$I3_SCRIPT/i3_$1"
    fi
}

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_reload_operator.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [all]: reload conky, dunst, swaybar, zathura and vis"
    echo "  [conky]: reload conky (system monitor)"
    echo "  [dunst]: reload dunst (notifier)"
    echo "  [i3bar]: reload swaybar (status bar)"
    echo "  [zathura]: reload zathura (PDF viewer)"
    echo "  [vis]: reload vis (cli-visualizer) "
    echo "  [Xresources]: reload X resources (XWayland apps only)"
    echo "  [xsslock]: restart swayidle (idle/lock daemon, xss-lock replacement)"
}

reload_conky () {
    # Conky (system monitor & shortcut table)
    if "$SWAY_SCRIPT/sway_conky_monitor_display.sh" default; then
        report_reload "Conky reloaded" 0
    else
        report_reload "Conky" 1
    fi
}

reload_i3bar () {
    if [[ -x $SWAY_SCRIPT/sway_bar_operator.sh ]]; then
        "$SWAY_SCRIPT/sway_bar_operator.sh" bar_reload || report_reload "swaybar" 1
    elif swaymsg reload > /dev/null; then
        report_reload "sway config reloaded (swaybar restarted)" 0
    else
        report_reload "swaybar" 1
    fi
}

reload_dunst () {
    # Dunst (notifier)
    if ! "$(script_path dunst_operator.sh)" reload_all; then
        report_reload "Dunst" 1
    fi
}

reload_vis () {
    # Vis (visualizer)
    if "$(script_path vis_colorchanger.sh)"; then
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
    # Only XWayland clients read X resources; sway sets DISPLAY when XWayland is enabled
    if [[ -z ${DISPLAY:-} ]]; then
        report_reload "Xresources: no XWayland (DISPLAY unset)" 1
        return
    fi
    if xrdb "$HOME/.Xresources"; then
        report_reload "Xresources reloaded (XWayland apps)" 0
    else
        report_reload "Xresources" 1
    fi

}

reload_xsslock () {
    if "$SWAY_SCRIPT/sway_idle_operator.sh" restart; then
        report_reload "swayidle restarted" 0
    else
        report_reload "swayidle" 1
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
        'i3bar'|'swaybar'|'bar')
            reload_i3bar
            ;;
        'zathura')
            reload_zathura
            ;;
        'vis')
            reload_vis
            ;;
        'xsslock'|'swayidle')
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
