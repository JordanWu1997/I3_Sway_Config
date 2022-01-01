#!/usr/bin/env bash

# Set default border width
if [ $# -eq 4 ]; then
    DEFAULT_WIDTH=$4
elif [ $# -eq 5 ] && [ $4 == 'pixel' ]; then
    DEFAULT_WIDTH="$4 $5"
else
    DEFAULT_WIDTH=$(awk '$0~/default_border_width/ {print $3,$4}' $HOME/.config/i3/config | awk 'NR==1')
fi

echo $DEFAULT_WIDTH

# Show titlebar for all windows
i3-msg [con_mark="^.*"] border normal

# Mark current window [Automark.py overwrite user-defined mark]
case $1 in
    # Show all marked window, modified from
    # -- https://github.com/EllaTheCat/dopamine-2020/blob/master/i3scripts/i3-list-windows
    "show")
        i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
            /usr/bin/grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
            /usr/bin/grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
            rofi -dmenu -sort -select -p 'Show [Mark]'
        ;;

    # Mark current window
    "mark")
        if [ $2 == "i3" ]; then
            i3-input -F "mark %s" -l 1 -P "Mark: "
        elif [ $2 == "rofi" ]; then
            i3-msg mark $(rofi -dmenu -lines 0 -width 35 -p 'Mark')
        else
            i3-input -F "mark %s" -l 1 -P "Mark: "
        fi
        ;;

    # Goto mark window
    "goto")
        if [ $2 == "i3" ]; then
            i3-input -F "[con_mark=%s] focus" -l 1 -P "Goto Window [Mark]: "
        elif [ $2 == "rofi" ]; then
            i3-msg [con_mark="$(rofi -dmenu -columns 10 -lines 2 -width 35 -select \
                -input ~/.config/i3/share/i3_automark_list.txt -p \
                'Goto Window [Mark]')"] focus
        fi
        ;;
    "show_then_goto")
        mark_title="$(i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
            /usr/bin/grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
            /usr/bin/grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
            rofi -dmenu -sort -auto-select -p 'Goto Window [Mark]')"
        mark_mark=$(echo $mark_title | awk '{print $1}')
        i3-msg [con_mark="$mark_mark"] focus
        ;;

    # Swap current window to mark window but remain focus
    "swap")
        if [ $2 == "i3" ]; then
            # Keep focus stay in current container
            if [ $3 == "stay" ]; then
                i3-input -F "swap container with mark %s, [con_mark=%s] focus" -l 1 -P "Swapto [Mark]: "
            else
                i3-input -F "swap container with mark %s" -l 1 -P "Swapto [Mark]: "
            fi
        elif [ $2 == "rofi" ]; then
            mark_title="$(rofi -dmenu -columns 10 -lines 2 -width 35 -select \
                -input ~/.config/i3/share/i3_automark_list.txt -p 'Swapto [Mark]')"
            mark_mark=$(echo $mark_title | awk '{print $1}')
            # Keep focus stay in current container
            if [ $3 == "stay" ]; then
                i3-msg "swap container with mark $mark_mark, [con_mark=$mark_mark] focus"
            else
                i3-msg "swap container with mark $mark_mark"
            fi
        fi
        ;;
    "show_then_swap")
        mark_title="$(i3-msg -t get_tree | jq '.. | objects | .name,.marks' | \
            /usr/bin/grep -B1 -A1 '[[]' | tr -d \\n\[ | sed 's/--/\n/g' | \
            /usr/bin/grep -v 'null' | awk -F '  ' '{print $2, $1}' | \
            rofi -dmenu -sort -auto-select --only-match -p 'Swapto [Mark]')"
        mark_mark=$(echo $mark_title | awk '{print $1}')
        # Keep focus stay in current container
        if [ $3 == "stay" ]; then
            i3-msg "swap container with mark $mark_mark, [con_mark=$mark_mark] focus"
        else
            i3-msg "swap container with mark $mark_mark"
        fi
        ;;

    # Print usage
    *)
        echo
        echo "Wrong Input: $0"
        echo "Available Usage: [i3_mark_operation.sh] [mark/goto/swap/show_then_goto/show_then_swap] [i3/rofi] ([border width])"
        echo
esac

# Restore border for all windows
i3-msg [con_mark="^.*"] border $DEFAULT_WIDTH
