#!/usr/bin/sh

killall conky
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_hotkey'
