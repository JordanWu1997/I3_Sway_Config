#!/usr/bin/env bash

reload_conky () {
    # Conky (system monitor & shortcut table)
    $I3_SCRIPT/i3_conky_valuechanger.sh system all && sleep 1
    $I3_SCRIPT/i3_conky_valuechanger.sh bindkey all && sleep 1
    notify-send -u low "Reload Mode" "Reload conky (system monitor)"
}

reload_i3bar () {
    $I3_SCRIPT/i3_bar_operator.sh bar_reload
    notify-send -u low "Reload Mode" "Reload i3bar (status bar)"
}

reload_dunst () {
    # Dunst (notifier)
    $I3_SCRIPT/i3_dunst_operator.sh reload_all
    notify-send -u low "Reload Mode" "Reload dunst (notifier)"
}

reload_vis () {
    # Vis (visualizer)
    $I3_SCRIPT/i3_vis_colorchanger.sh
    notify-send -u low "Reload Mode" "Reload vis (cli-equalizer)"
}

reload_zathura () {
    # Zathura (PDF viewer)
    zathura-pywal -a 0.7
    notify-send -u low "Reload Mode" "Reload zathura (PDF viewer)"
}

# Main reload pipline
reload_pipeline () {
    # Reload programs for new color theme
    reload_dunst
    reload_conky
    reload_i3bar
    reload_zathura
    reload_vis
}

# Main
reload_pipeline
