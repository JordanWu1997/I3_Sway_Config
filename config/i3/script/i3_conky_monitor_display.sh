#!/usr/bin/env bash

case $1 in
    "all")
        killall conky
        xrandr --output eDP1 --primary --left-of HDMI1
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        sleep 2
        xrandr --output HDMI1 --primary --right-of eDP1
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        i3-msg restart
        ;;
    "primary")
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        i3-msg restart
        ;;
    "primary_only")
        killall conky
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        i3-msg restart
        ;;
    "eDP1")
        killall conky
        xrandr --output eDP1 --primary --left-of HDMI1
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        sleep 2
        xrandr --output HDMI1 --primary --right-of eDP1
        i3-msg restart
        ;;
    "default")
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        ;;
    *)
        echo "Availble option: all/primary/primary_only/eDP1"
esac
