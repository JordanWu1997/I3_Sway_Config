#!/usr/bin/env bash

# Rofi selector configuration
ROFI_SELECTOR_CONFIG="$HOME/.config/rofi/config_i3workspace.rasi"

# Workspace list
WS_NAME_LIST="$HOME/.config/i3/share/i3_workspace_name_list.txt"

# Set workspace list to workspace array
readarray WS_ARRAY < ${WS_NAME_LIST}

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
    echo "  i3_workspace_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [float_current]: make all windows in current workspace floating"
    echo "  [tile_current]: make all window in current workspace tiled"
    echo "  [rename]: rename current workspace"
    echo "  [kill_current]: kill current workspace"
    echo "  [goto]: goto selected workspace"
    echo "  [move_container]: move current window and focus to selected workspace"
    echo "  [move_container_not_focus]: move current window but not focus to selected workspace"
    echo "  [swap]: swap current workspace with selected workspace"
    echo "  [kill]: kill selected workspace"
    echo "  [save]: save layout in selected workspace"
    echo "  [restore]: restore layout in selected workspace"
    echo "  [swap_with_index]: swap current workspace with index (start from 0)"
    echo "  [swap_next]: swap current workspace with next workspace"
    echo "  [swap_prev]: swap current workspace with previous workspace"
    echo "  [save_all]: save layout in all workspaces"
    echo "  [restore_all]: restore layout in all workspaces"
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

workspace_operation () {
    case $1 in
        # For current workspace
        "float_current")
            i3-msg [workspace='__focused__'] floating enable
            ;;
        "tile_current")
            i3-msg [workspace='__focused__'] floating disable
            ;;
        "rename_current")
            i3-msg rename workspace to $(rofi -dmenu -line 0 -p "New Workspace Name")
            ;;
        "kill_current")
            i3-resurrect save
            i3-msg [workspace='__focused__'] kill
            ;;
        "save_current")
            i3-resurrect save
            ;;
        "restore_current")
            i3-resurrect restore
            ;;
        # For selected workspace
        "goto")
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Go to WS")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-msg workspace ${WS}
            fi
            ;;
        "move_container_not_focus")
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Move WD to WS")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-msg move container to workspace ${WS}
            fi
            ;;
        "move_container")
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Move WD and focus to")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-msg move container to workspace ${WS}
                i3-msg workspace back_and_forth
            fi
            ;;
        "swap")
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Swap with WS")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-workspace-swap -d ${WS}
            fi
            ;;
        "kill")
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Kill WS")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-msg workspace ${WS}
                i3-resurrect save
                i3-msg [workspace='__focused__'] kill
                i3-msg workspace back_and_forth
            fi
            ;;
        "save")
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Save WS")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-msg workspace ${WS}
            fi
            ;;
        "restore")
            HIDDEN_STATE=$(awk '$0~/default_i3bar_hidden_state/' ~/.config/i3/config | cut -d' ' -f3)
            i3-msg bar hidden_state show bar_mode
            WS=$(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Restore WS")
            i3-msg bar hidden_state hide bar_mode
            if [[ ! -z ${WS} ]]; then
                i3-resurrect restore -w ${WS}
            fi
            ;;
        "swap_with_index")
            if (( $2 < ${MAX_NUM_WS} )); then
                i3-workspace-swap -d ${WS_ARRAY[$2]}
            else
                echo
                echo Input index $2 is out of range.
                echo Maximal availble index: $(( ${MAX_NUM_WS} - 1)) exit
            fi
            ;;
        "swap_next")
            # Load current workspace
            CURRENT_WS_NUM=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
                tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)
            workspace_next_WS_NUM $CURRENT_WS_NUM
            NEXT_WS_NAME="${WS_ARRAY[$(( ${NEXT_WS_NUM} - 1 ))]}"
            i3-workspace-swap -d ${NEXT_WS_NAME}
            ;;
        "swap_prev")
            # Load current workspace
            CURRENT_WS_NUM=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
                tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)
            workspace_prev_WS_NUM $CURRENT_WS_NUM
            PREV_WS_NAME="${WS_ARRAY[$((${PREV_WS_NUM} - 1))]}"
            i3-workspace-swap -d ${PREV_WS_NAME}
            ;;
        # For all workspaces
        "save_all")
            # Loop all defined workspaces
            counter=0
            for WS in ${WS_ARRAY[@]}; do
                i3-resurrect save -w ${WS}
            done
            ;;
        "restore_all")
            # Loop all defined workspaces
            for WS in ${WS_ARRAY[@]}; do
                i3-resurrect restore -w ${WS}
            done
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
workspace_operation $1 $2
