#!/usr/bin/env bash

reload_conky () {
    # Conky (system monitor & shortcut table)
    $I3_SCRIPT/i3_conky_colorchanger.sh system all; sleep 1
    $I3_SCRIPT/i3_conky_colorchanger.sh bindkey all; sleep 1
    notify-send -u low "Theme Mode" "Reload conky"
}

reload_dunst () {
    # Dunst (notifier)
    $I3_SCRIPT/i3_dunst_walcolor.sh both
    notify-send -u low "Theme Mode" "Reload dunst (notifier)"
}

reload_xsslock () {
    # Xsslock (lock for xwindow)
    $I3_SCRIPT/i3_xsslock_operator.sh current
    notify-send -u low "Theme Mode" "Reload xsslock (session lock)"
}

reload_vis () {
    # Vis (visualizer)
    $I3_SCRIPT/i3_vis_colorchanger.sh
    notify-send -u low "Theme Mode" "Reload vis (cli-equalizer)"
}

reload_zathura () {
    # Zathura (PDF viewer)
    zathura-pywal -a 0.7
    notify-send -u low "Theme Mode" "Reload zathura (PDF viewer)"
}

# Main reload pipline
reload_pipeline () {
    # Reload programs for new color theme
    reload_conky
    reload_dunst
    reload_xsslock
    reload_vis
    reload_zathura
    # Restart i3
    i3-msg restart
    # Reload picom
    $I3_SCRIPT/i3_picom_operator.sh default
}

reload_pipeline
