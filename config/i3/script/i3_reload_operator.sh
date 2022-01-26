#!/usr/bin/env bash

# Conky (system monitor & shortcut table)
$I3_SCRIPT/i3_conky_colorchanger.sh system all; sleep 1
$I3_SCRIPT/i3_conky_colorchanger.sh bindkey all; sleep 1
notify-send -u low "Theme Mode" "Reload conky"

# Dunst (notifier)
$I3_SCRIPT/i3_dunst_walcolor.sh both
notify-send -u low "Theme Mode" "Reload dunst (notifier)"

# Xsslock (lock for xwindow)
$I3_SCRIPT/i3_xsslock_operator.sh current
notify-send -u low "Theme Mode" "Reload xsslock (session lock)"

# Vis (visualizer)
$I3_SCRIPT/i3_vis_colorchanger.sh
notify-send -u low "Theme Mode" "Reload vis (cli-equalizer)"

# Zathura (PDF viewer)
zathura-pywal -a 0.7
notify-send -u low "Theme Mode" "Reload zathura (PDF viewer)"

# Restart i3
i3-msg restart
