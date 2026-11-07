#!/usr/bin/env bash
# Ported from i3_workspace_operator.sh for sway.
# Replaced X11/i3-only tools:
#   - i3-msg                     -> swaymsg
#   - i3-workspace-swap -d WS    -> native rename-based swap (workspace_swap below)
#   - i3-resurrect save/restore  -> sway_resurrect_save / sway_resurrect_restore below.
#       sway has no "append_layout"/placeholder swallowing, so the split layout and
#       window geometry are NOT restored. "save" records every window of a workspace
#       (app_id or X11 class, title, floating, and the command line read from
#       /proc/<pid>/cmdline) to a JSON file; "restore" relaunches those commands on
#       that workspace (sway places a new window on the workspace its "exec" was
#       issued from, by pid). Apps that hand off to an already running instance
#       (e.g. a second browser window) open where that instance decides.
# Subcommands and arguments are identical to the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
ICON="$HOME/.config/i3/share/64x64/window.png"

# Rofi selector configuration
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_i3workspace.rasi"

# Workspace list
WS_NAME_LIST="$HOME/.config/i3/share/i3_workspace_name_list.txt"

# Saved workspace programs (sway replacement of ~/.i3/i3-resurrect)
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sway-resurrect"

# Set workspace list to workspace array
readarray -t WS_ARRAY < "$WS_NAME_LIST"

# Maximal number of workspaces
MAX_NUM_WS=${#WS_ARRAY[@]}

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_workspace_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [rename_current]: rename current workspace"
    echo "  [kill_current]: kill current workspace (programs are saved first)"
    echo "  [save_current]: save programs in current workspace"
    echo "  [restore_current]: relaunch saved programs in current workspace"
    echo "  [goto]: goto selected workspace"
    echo "  [goto_with_input]: goto input workspace"
    echo "  [move_container]: move current window and focus to selected workspace"
    echo "  [move_container_not_focus]: move current window but not focus to selected workspace"
    echo "  [move_container_with_input]: move current window and focus to input workspace"
    echo "  [move_container_to_output]: move current window and focus to input output"
    echo "  [move_workspace_and_focus]: move workspace and focus to output display"
    echo "  [swap]: swap current workspace with selected workspace"
    echo "  [kill]: kill selected workspace"
    echo "  [save]: save programs in selected workspace"
    echo "  [restore]: relaunch saved programs in selected workspace"
    echo "  [swap_with_input]: swap current workspace with input name"
    echo "  [swap_with_index]: swap current workspace with index (start from 1)"
    echo "  [swap_next]: swap current workspace with next workspace"
    echo "  [swap_prev]: swap current workspace with previous workspace"
    echo "  [save_all]: save programs in all workspaces"
    echo "  [restore_all]: relaunch saved programs in all workspaces"
    echo ""
    echo "NOTE: sway cannot restore split layouts/geometry (no append_layout);"
    echo "      save/restore only records and relaunches the programs."
}

workspace_next_WS_NUM () {
    if (( $1 == ${MAX_NUM_WS} )); then
        NEXT_WS_NUM=1
    else
        NEXT_WS_NUM=$(( $1 + 1 ))
    fi
}

workspace_prev_WS_NUM () {
    if (( $1 == 1 )); then
        PREV_WS_NUM=${MAX_NUM_WS}
    else
        PREV_WS_NUM=$(( $1 - 1 ))
    fi
}

focused_workspace_name () {
    swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .name'
}

# Show the mode bar while choosing a workspace, then restore its prior state.
workspace_rofi () {
    local previous_state rofi_status
    previous_state=$(swaymsg -t get_bar_config bar_mode -r 2>/dev/null |
        jq -er '.hidden_state | select(. == "show" or . == "hide")' 2>/dev/null) || previous_state=
    if [[ $previous_state == hide ]]; then
        swaymsg 'bar bar_mode hidden_state show' >/dev/null || true
    fi
    rofi "$@"
    rofi_status=$?
    if [[ $previous_state == hide ]]; then
        swaymsg 'bar bar_mode hidden_state hide' >/dev/null || true
    fi
    return "$rofi_status"
}

# Escape a workspace name for use inside double quotes in a sway command
ws_quote () {
    local name=${1//\\/\\\\}
    printf '"%s"' "${name//\"/\\\"}"
}

# Swap the contents of the focused workspace and workspace $1 (i3-workspace-swap -d).
# Implemented with three renames, so each workspace keeps its output; the focus
# stays on the (renamed) content that was focused.
workspace_swap () {
    local target=$1 current tmp="__sway_workspace_swap__"
    [[ -n $target ]] || return 1
    current=$(focused_workspace_name)
    [[ -n $current && $current != "$target" ]] || return 0
    if swaymsg -t get_workspaces -r | jq -e --arg ws "$target" 'any(.[]; .name == $ws)' >/dev/null; then
        swaymsg "rename workspace $(ws_quote "$current") to $(ws_quote "$tmp")" >/dev/null &&
            swaymsg "rename workspace $(ws_quote "$target") to $(ws_quote "$current")" >/dev/null &&
            swaymsg "rename workspace $(ws_quote "$tmp") to $(ws_quote "$target")" >/dev/null
    else
        # Target does not exist yet: the current content simply takes its name
        swaymsg "rename workspace $(ws_quote "$current") to $(ws_quote "$target")" >/dev/null
    fi
}

# File holding the saved programs of workspace $1
resurrect_file () {
    printf '%s/workspace_%s.json\n' "$RESURRECT_DIR" "$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_')"
}

# Save programs of workspace $1 (default: focused). $2=quiet skips notifications.
sway_resurrect_save () {
    local ws=${1:-$(focused_workspace_name)} quiet=$2 file windows entries pid id app title floating cmd
    [[ -n $ws ]] || return 1
    file=$(resurrect_file "$ws")
    windows=$(swaymsg -t get_tree -r | jq -c --arg ws "$ws" '
        first(.. | objects | select(.type? == "workspace" and .name == $ws)) // empty
        | [.. | objects
            | select((.type? == "con" or .type? == "floating_con")
                and ((.nodes? // []) | length) == 0 and .pid? != null)]
        | unique_by(.id) | .[]
        | {id, pid, app: (.app_id // .window_properties.class // ""),
           title: (.name // ""), floating: (.type == "floating_con")}')
    entries="[]"
    while IFS= read -r line; do
        [[ -z $line ]] && continue
        pid=$(jq -r '.pid' <<< "$line")
        [[ -r /proc/$pid/cmdline ]] || continue
        cmd=$(jq -Rs 'split("\u0000") | map(select(length > 0))' < "/proc/$pid/cmdline")
        [[ $cmd == "[]" ]] && continue
        entries=$(jq -c --argjson e "$line" --argjson cmd "$cmd" \
            '. + [$e + {command: $cmd, cwd: null} | del(.id, .pid)]' <<< "$entries")
    done <<< "$windows"
    if [[ $entries == "[]" ]]; then
        [[ $quiet == quiet ]] || notify-send -u low "Sway Workspace" "Nothing to save in workspace $ws" --icon="$ICON"
        return 0
    fi
    mkdir -p "$RESURRECT_DIR"
    jq -n --arg ws "$ws" --argjson programs "$entries" \
        '{workspace: $ws, saved: (now | todate), programs: $programs}' > "$file"
    [[ $quiet == quiet ]] || notify-send -u low "Sway Workspace" "Saved $(jq length <<< "$entries") program(s) of workspace $ws\n(layout is not saved on sway)" --icon="$ICON"
}

# Relaunch saved programs of workspace $1 (default: focused). $2=quiet skips notifications.
sway_resurrect_restore () {
    local ws=${1:-$(focused_workspace_name)} quiet=$2 file count=0 launcher argv
    [[ -n $ws ]] || return 1
    file=$(resurrect_file "$ws")
    if [[ ! -f $file ]]; then
        [[ $quiet == quiet ]] || notify-send -u low "Sway Workspace" "No saved programs for workspace $ws" --icon="$ICON"
        return 0
    fi
    while IFS= read -r argv; do
        [[ -z $argv ]] && continue
        # A tiny launcher script avoids sway command quoting issues; it "exec"s the
        # program so the window pid descends from sway's exec (workspace-by-pid).
        launcher=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/sway_resurrect_XXXXXX.sh") || return 1
        {
            echo '#!/usr/bin/env bash'
            echo 'rm -f -- "$0"'
            printf 'exec'
            jq -r '.[] | @sh' <<< "$argv" | while IFS= read -r word; do printf ' %s' "$word"; done
            echo
        } > "$launcher"
        swaymsg "workspace --no-auto-back-and-forth $(ws_quote "$ws"); exec bash $launcher" >/dev/null
        count=$((count + 1))
        sleep 0.2
    done < <(jq -c '.programs[].command' "$file")
    [[ $quiet == quiet ]] || notify-send -u low "Sway Workspace" "Relaunched ${count} program(s) on workspace $ws\n(layout is not restored on sway)" --icon="$ICON"
}

workspace_operation () {
    case $1 in
        # For current workspace
        "rename_current")
            WS=$(rofi -dmenu -l 0 -p "New Workspace Name")
            [[ -n $WS ]] && swaymsg "rename workspace to $(ws_quote "$WS")"
            ;;
        "kill_current")
            sway_resurrect_save "" quiet
            swaymsg '[workspace=__focused__] kill'
            ;;
        "save_current")
            sway_resurrect_save
            ;;
        "restore_current")
            sway_resurrect_restore
            ;;
        # For selected workspace
        "goto")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Go to WS")
            if [[ -n ${WS} ]]; then
                swaymsg "workspace $(ws_quote "$WS")"
            fi
            ;;
        "goto_with_input")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -p "Go to WS")
            if [[ -n ${WS} ]]; then
                swaymsg "workspace $(ws_quote "$WS")"
            fi
            ;;
        "move_container_not_focus")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Move WD to WS")
            if [[ -n ${WS} ]]; then
                swaymsg "move container to workspace $(ws_quote "$WS")"
            fi
            ;;
        "move_container")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Move WD and focus to")
            if [[ -n ${WS} ]]; then
                swaymsg "move container to workspace $(ws_quote "$WS")"
                swaymsg "workspace $(ws_quote "$WS")"
            fi
            ;;
        "move_container_with_input")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -p "Move WD and focus to")
            if [[ -n ${WS} ]]; then
                swaymsg "move container to workspace $(ws_quote "$WS")"
                swaymsg "workspace $(ws_quote "$WS")"
            fi
            ;;
        "move_container_to_output")
            swaymsg move container to output "$2"; sleep 0.1
            swaymsg focus output "$2"
            ;;
        "move_workspace_and_focus")
            # Load current workspace
            CURRENT_WS_NAME=$(focused_workspace_name)
            sleep 0.05
            swaymsg move workspace to output "$2"; sleep 0.1
            swaymsg "workspace $(ws_quote "$CURRENT_WS_NAME")"
            ;;
        "swap")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Swap with WS")
            if [[ -n ${WS} ]]; then
                workspace_swap "$WS"
            fi
            ;;
        "kill")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Kill WS")
            if [[ -n ${WS} ]]; then
                swaymsg "workspace $(ws_quote "$WS")"
                sway_resurrect_save "$WS" quiet
                swaymsg '[workspace=__focused__] kill'
                swaymsg workspace back_and_forth
            fi
            ;;
        "save")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Save WS")
            if [[ -n ${WS} ]]; then
                sway_resurrect_save "$WS"
            fi
            ;;
        "restore")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Restore WS")
            if [[ -n ${WS} ]]; then
                sway_resurrect_restore "$WS"
            fi
            ;;
        "swap_with_input")
            WS=$(workspace_rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -p "Swap with WS")
            if [[ -n ${WS} ]]; then
                workspace_swap "$WS"
            fi
            ;;
        "swap_with_index")
            if [[ $2 =~ ^[0-9]+$ ]] && (( $2 >= 1 && $2 <= MAX_NUM_WS )); then
                INDEX=$(( $2 - 1 ))
                workspace_swap "${WS_ARRAY[${INDEX}]}"
            else
                echo
                echo Input index $2 is out of range.
                echo Minimal availble index: 1
                echo Maximal availble index: $(( ${MAX_NUM_WS} ))
                exit
            fi
            ;;
        "swap_next")
            # Load current workspace
            CURRENT_WS_NUM=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
            workspace_next_WS_NUM $CURRENT_WS_NUM
            NEXT_WS_NAME="${WS_ARRAY[$(( ${NEXT_WS_NUM} - 1 ))]}"
            workspace_swap "$NEXT_WS_NAME"
            ;;
        "swap_prev")
            # Load current workspace
            CURRENT_WS_NUM=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
            workspace_prev_WS_NUM $CURRENT_WS_NUM
            PREV_WS_NAME="${WS_ARRAY[$((${PREV_WS_NUM} - 1))]}"
            workspace_swap "$PREV_WS_NAME"
            ;;
        # For all workspaces
        "save_all")
            # Loop all defined workspaces
            for WS in "${WS_ARRAY[@]}"; do
                [[ -n $WS ]] && sway_resurrect_save "$WS" quiet
            done
            notify-send -u low "Sway Workspace" "Saved programs of all workspaces\n(layout is not saved on sway)" --icon="$ICON"
            ;;
        "restore_all")
            # Loop all defined workspaces
            CURRENT_WS_NAME=$(focused_workspace_name)
            for WS in "${WS_ARRAY[@]}"; do
                [[ -n $WS ]] && sway_resurrect_restore "$WS" quiet
            done
            swaymsg "workspace --no-auto-back-and-forth $(ws_quote "$CURRENT_WS_NAME")" >/dev/null
            notify-send -u low "Sway Workspace" "Relaunched saved programs of all workspaces\n(layout is not restored on sway)" --icon="$ICON"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
workspace_operation "$1" "$2"
