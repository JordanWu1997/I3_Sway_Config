#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_conky_monitor_display.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [all]: conky shows on eDP1 and HDMI1"
    echo "  [primary]: conky shows on primary display"
    echo "  [primary_only]: conky only shows on primary display"
    echo "  [eDP1]: conky shows on eDP1"
    echo "  [default]: same as [primary]"
}

conky_display () {
    case $1 in
        "all")
            killall conky
            xrandr --output eDP1 --primary --left-of HDMI1
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey &> /dev/null'
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system &> /dev/null'
            sleep 2
            xrandr --output HDMI1 --primary --right-of eDP1
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey &> /dev/null'
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system &> /dev/null'
            i3-msg restart
            ;;
        "primary")
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey &> /dev/null'
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system &> /dev/null'
            i3-msg restart
            ;;
        "primary_only")
            killall conky
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey &> /dev/null'
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system &> /dev/null'
            i3-msg restart
            ;;
        "eDP1")
            killall conky
            xrandr --output eDP1 --primary --left-of HDMI1
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey &> /dev/null'
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system &> /dev/null'
            sleep 2
            xrandr --output HDMI1 --primary --right-of eDP1
            i3-msg restart
            ;;
        "default")
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey &> /dev/null'
            i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system &> /dev/null'
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
conky_display $1
