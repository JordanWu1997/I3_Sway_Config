#!/bin/bash

# Set default border width
if [ $# -eq 4 ]; then
    default_width=$4
elif [ $# -eq 5 ] && [ $4 == 'pixel' ]; then
    default_width="$4 $5"
else
    default_width=$(awk '$0~/default_border_width/ {print $3,$4}' $HOME/.config/i3/config | awk 'NR==1')
fi

echo $default_width

# Show titlebar for all windows
i3-msg [con_mark="^.*"] border normal

# Mark current window [Automark.py overwrite user-defined mark]
if [ $1 == "mark" ]; then
    if [ $2 == "i3" ]; then
        i3-input -F "mark %s" -l 1 -P "Mark: "
    elif [ $2 == "rofi" ]; then
        i3-msg mark $(rofi -dmenu -lines 0 -width 35 -p 'Mark')
    else
        i3-input -F "mark %s" -l 1 -P "Mark: "
    fi
# Goto mark window
elif [ $1 == "goto" ]; then
    if [ $2 == "i3" ]; then
        i3-input -F "[con_mark=%s] focus" -l 1 -P "Goto Window [Mark]: "
    elif [ $2 == "rofi" ]; then
        i3-msg [con_mark="$(rofi -dmenu -columns 10 -lines 2 -width 35 -select -input ~/.config/i3/share/i3_automark_list.txt -p 'Goto Window [Mark]')"] focus
    fi
# Swap current window to mark window but remain focus
elif [ $1 == "swap" ]; then
    if [ $2 == "i3" ]; then
        # Keep focus stay in current container
        if [ $3 == "stay" ]; then
            i3-input -F "swap container with mark %s, [con_mark=%s] focus" -l 1 -P "Swapto [Mark]: "
        else
            i3-input -F "swap container with mark %s" -l 1 -P "Swapto [Mark]: "
        fi
    elif [ $2 == "rofi" ]; then
        mark_title="$(rofi -dmenu -columns 10 -lines 2 -width 35 -select -input ~/.config/i3/share/i3_automark_list.txt -p 'Swapto [Mark]')"
        # Keep focus stay in current container
        if [ $3 == "stay" ]; then
            i3-msg "swap container with mark $mark_title, [con_mark=$mark_title] focus"
        else
            i3-msg "swap container with mark $mark_title"
        fi
    fi
else
    echo
    echo "Wrong Input:"
    echo "Available Usage: [i3_mark_operation.sh] [mark/goto/swap] [i3/rofi] ([border width])"
    echo
fi

# Restore border for all windows
i3-msg [con_mark="^.*"] border $default_width