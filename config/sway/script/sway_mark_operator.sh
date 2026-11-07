#!/usr/bin/env bash
# Ported from i3_mark_operator.sh for sway.
# Replaced X11/i3-only tools:
#   - i3-input (selector "i3")          -> rofi -dmenu prompt, %s substituted, sent with swaymsg
#   - i3-msg / i3-msg -t get_tree       -> swaymsg / swaymsg -t get_tree
#   - grep-based parsing of i3 tree     -> jq (sway emits "marks": [] on every node)
#   - i3_automark.py (re-mark)          -> sway_automark.py (sway socket, app_id windows)
# Subcommands and arguments are identical to the i3 version
# (e.g. "mark rofi none title_on").

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
SWAY_CONFIG="$HOME/.config/sway/config"

# Rofi configuration
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_i3mark.rasi"
# Mark input list for rofi
ROFI_AUTOMARK_INPUT_TEXT="$HOME/.config/rofi/i3_automark_list.txt"

mark_rofi () {
    local output_width menu_width=640

    # Keep the grid within the focused output on narrow displays.
    output_width=$(swaymsg -t get_workspaces -r 2>/dev/null |
        jq -r '.[] | select(.focused) | .rect.width' 2>/dev/null)
    if [[ $output_width =~ ^[0-9]+$ ]] && (( output_width > 48 && output_width - 48 < menu_width )); then
        menu_width=$((output_width - 48))
    fi

    # [SWAY] no per-window placement on Wayland; rofi opens on the focused output
    rofi "$@" -theme-str "window { width: ${menu_width}px; }"
}

# [SWAY] i3-input replacement: ask for a value with rofi and run the i3-input
# style format string (every %s is replaced by the input).
i3_input_compat () {
    local format=$1 prompt=$2 value
    value=$(mark_rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" -p "${prompt% }")
    [[ -z $value ]] && return
    swaymsg "${format//%s/$value}"
}

# Windows that carry marks, one per line: "<mark>" <title>
# ($1 = all: every mark joined by ",", otherwise the first mark only)
list_marked_windows () {
    swaymsg -t get_tree -r | jq -r --arg all "${1:-first}" '
        .. | objects | select(.type? == "con" or .type? == "floating_con")
        | select((.marks? // []) | length > 0)
        | "\"" + (if $all == "all" then (.marks | join(",")) else .marks[0] end) + "\" " + (.name // "")'
}

# Extract the mark from a rofi selection ("<mark>" title, or a typed mark)
selection_to_mark () {
    local selection=$1
    if [[ $selection =~ ^\"([^\"]*)\" ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    else
        echo "$selection" | awk '{print $1}' | cut -d',' -f1
    fi
}

# Automark marks
readarray -t ALL_AUTOMARK_LIST < "$HOME/.config/i3/share/i3_automark_list.txt"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_mark_operator.sh [operations] [input/selector] [titlebar]"
    echo ""
    echo "OPERATIONS"
    echo "  [mark]: add mark to window"
    echo "  [unmark]: unmark existing mark"
    echo "  [unmark_all]: unmark all existing marks"
    echo "  [unmark_all_automark]: unmark all automarked marks"
    echo "  [unmark_all_automark_and_remark]: unmark all automarked marks and re-automark"
    echo "  [goto]: go to marked window"
    echo "  [swap]: swap with marked window"
    echo "  [show_then_goto]: show all marks and go to marked window"
    echo "  [show_then_swap]: show all marks and swap with marked window"
    echo ""
    echo "INPUT/SELECTOR"
    echo "  [i3]: i3-input style prompt (rofi on sway)"
    echo "  [rofi]: use rofi as input/selector"
    echo "  [none]: do not use input/selector"
    echo ""
    echo "TITLEBAR"
    echo "  [title_on]: show window title bar when selecting"
    echo "  [title_off]: do not show winow title bar when selecting"
}

# Operation for vim-style mark
mark_operation () {
    case $1 in
        "show")
            list_marked_windows all | mark_rofi -dmenu -sort -select -p 'Show [Mark]'
            ;;
        # Mark current window
        "mark")
            if [[ $2 == "rofi" ]]; then
                mark_mark=$(mark_rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" -p 'Mark')
                if [[ -z ${mark_mark} ]]; then
                    return
                fi
                swaymsg "mark --add \"${mark_mark}\""
            else
                i3_input_compat "mark --add %s" "Mark: "
            fi
            ;;
        # Unmark current window
        "unmark")
            if [[ $2 == "rofi" ]]; then
                mark_mark=$(mark_rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" -p 'Unmark')
                if [[ -n ${mark_mark} ]]; then
                    swaymsg "unmark \"${mark_mark}\""
                fi
            else
                i3_input_compat "unmark %s" "Unmark: "
            fi
            ;;
        # Unmark all marks
        "unmark_all")
            swaymsg unmark
            ;;
        # Unmark all automark marks
        "unmark_all_automark")
            for mark in "${ALL_AUTOMARK_LIST[@]}"; do
                [[ -z ${mark} ]] && continue
                swaymsg unmark "${mark}"
            done
            ;;
        "unmark_all_automark_and_remark")
            for mark in "${ALL_AUTOMARK_LIST[@]}"; do
                [[ -z ${mark} ]] && continue
                swaymsg unmark "${mark}"
            done
            python3 "$SWAY_SCRIPT/sway_automark.py"
            ;;
        # Goto mark window
        "goto")
            if [[ $2 == "i3" ]]; then
                i3_input_compat "[con_mark=\"%s\"] focus" "Goto Window [Mark]: "
            elif [[ $2 == "rofi" ]]; then
                mark_mark=$(mark_rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" \
                    -select -input "${ROFI_AUTOMARK_INPUT_TEXT}" \
                    -p 'Goto Window [Mark]')
                if [[ -z ${mark_mark} ]]; then
                    return
                fi
                swaymsg "[con_mark=\"${mark_mark}\"] focus"
            fi
            ;;
        "show_then_goto")
            mark_title="$(list_marked_windows | mark_rofi -dmenu -sort -auto-select -p 'Goto Window [Mark]')"
            mark_mark=$(selection_to_mark "$mark_title")
            if [[ -z ${mark_mark} ]]; then
                return
            fi
            swaymsg "[con_mark=\"$mark_mark\"] focus"
            ;;
        # Swap current window to mark window but remain focus
        "swap")
            if [[ $2 == "i3" ]]; then
                # Keep focus stay in current container
                if [[ $3 == "stay" ]]; then
                    i3_input_compat "swap container with mark \"%s\", [con_mark=\"%s\"] focus" "Swap with Window [Mark]: "
                else
                    i3_input_compat "swap container with mark \"%s\"" "Swap with Window [Mark]: "
                fi
            elif [[ $2 == "rofi" ]]; then
                mark_title="$(mark_rofi -dmenu -config "${ROFI_SELECTOR_CONFIG}" -select \
                    -input "${ROFI_AUTOMARK_INPUT_TEXT}" -p 'Swap with Window [Mark]')"
                mark_mark=$(selection_to_mark "$mark_title")
                if [[ -z ${mark_mark} ]]; then
                    return
                fi
                # Keep focus stay in current container
                if [[ $3 == "stay" ]]; then
                    swaymsg "swap container with mark \"$mark_mark\", [con_mark=\"$mark_mark\"] focus"
                else
                    swaymsg "swap container with mark \"$mark_mark\""
                fi
            fi
            ;;
        "show_then_swap")
            mark_title="$(list_marked_windows | mark_rofi -dmenu -sort -auto-select -p 'Swap with Window [Mark]')"
            mark_mark=$(selection_to_mark "$mark_title")
            if [[ -z ${mark_mark} ]]; then
                return
            fi
            # Keep focus stay in current container
            if [[ $3 == "stay" ]]; then
                swaymsg "swap container with mark \"$mark_mark\", [con_mark=\"$mark_mark\"] focus"
            else
                swaymsg "swap container with mark \"$mark_mark\""
            fi
            ;;
        # Print usage
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Read "set $<name> <value>" from the sway config (same variable names as i3)
sway_config_var () {
    awk -v n="\$$1" '$1 == "set" && $2 == n {print $3; exit}' "$SWAY_CONFIG" 2>/dev/null
}

# Main
if [[ $4 == 'title_on' ]]; then
    # Get current titlebar/border setup
    DEFAULT_WIDTH=$(sway_config_var default_border_width)
    DEFAULT_STYLE=$(sway_config_var default_titlebar_style)
    DEFAULT_FLOATING_STYLE=$(sway_config_var default_floating_titlebar_style)
    # Show titlebar
    swaymsg "[con_mark=\"^.*\"] border normal $DEFAULT_WIDTH"
    # Operation with mark
    mark_operation "$1" "$2" "$3"
    # Restore defaults
    swaymsg "[all] border $DEFAULT_STYLE $DEFAULT_WIDTH"
    swaymsg "[floating] border $DEFAULT_FLOATING_STYLE $DEFAULT_WIDTH"
else
    # Do not show titlebar for all windows
    mark_operation "$1" "$2" "$3"
fi
