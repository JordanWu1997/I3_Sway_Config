#!/usr/bin/env bash

killall conky

xrandr --output eDP1 --auto --primary --left-of HDMI1
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_hotkey'
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'

sleep 2

xrandr --output HDMI1 --auto --primary --right-of eDP1
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_hotkey'
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
