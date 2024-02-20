#!/usr/bin/env bash

ICON="$HOME/.config/i3/share/reload.png"

reload_conky () {
    # Conky (system monitor & shortcut table)
    $I3_SCRIPT/i3_conky_valuechanger.sh system all && sleep 1
    $I3_SCRIPT/i3_conky_valuechanger.sh bindkey all && sleep 1
    notify-send -u low "Reload Mode" "Reload conky (system monitor)" --icon=${ICON}
}

reload_i3bar () {
    $I3_SCRIPT/i3_bar_operator.sh bar_reload
    notify-send -u low "Reload Mode" "Reload i3bar (status bar)" --icon=${ICON}
}

reload_dunst () {
    # Dunst (notifier)
    $I3_SCRIPT/i3_dunst_operator.sh reload_all
    notify-send -u low "Reload Mode" "Reload dunst (notifier)" --icon=${ICON}
}

reload_vis () {
    # Vis (visualizer)
    $I3_SCRIPT/i3_vis_colorchanger.sh
    notify-send -u low "Reload Mode" "Reload vis (cli-equalizer)" --icon=${ICON}
}

reload_zathura () {
    # Zathura (PDF viewer)
    zathura-pywal -a 0.7
    notify-send -u low "Reload Mode" "Reload zathura (PDF viewer)" --icon=${ICON}
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
