#!/bin/bash

# Show titlebar
i3-msg [con_mark="^.*"] border normal

# Use i3-input as input
if [ "$1" == "i3" ]; then
    i3-input -F "mark %s" -l 1 -P "Mark: "
fi

# Use rofi as input
if [ "$1" == "rofi" ]; then
    i3-msg mark $(rofi -dmenu -lines 0 -width 25 -p 'Mark')
fi

# Restore border
i3-msg [con_mark="^.*"] border pixel $2
