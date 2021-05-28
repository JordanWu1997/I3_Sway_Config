#!/usr/bin/env bash

killall conky

xrandr --output eDP1 --auto --primary --left-of HDMI1
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_hotkey_v2'
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system_v2'

sleep 2

xrandr --output HDMI1 --auto --primary --right-of eDP1
