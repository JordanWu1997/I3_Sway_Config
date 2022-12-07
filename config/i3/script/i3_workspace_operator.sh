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
    echo "  [goto]: goto selected workspace"
    echo "  [swap]: swap current workspace with selected workspace"
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
        "goto")
            i3-msg workspace $(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Goto WS")
            ;;
        "swap")
            i3-workspace-swap -d $(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Swap with WS")
           ;;
        "save")
            i3-resurrect save -w $(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Save WS")
            ;;
        "restore")
            i3-resurrect restore -w $(rofi -dmenu -i -config ${ROFI_SELECTOR_CONFIG} -input ${WS_NAME_LIST} -p "Restore WS")
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
