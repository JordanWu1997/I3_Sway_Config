#!/usr/bin/env bash

# i3 workspace name config file
WS_NAME_CONFIG="$HOME/.config/i3/config.d/i3_workspace_name.config"

# workspace name list text file for rofi selector
WS_NAME_LIST_TXT="$HOME/.config/i3/share/i3_workspace_name_list.txt"

initialize () {
    if [[ -f ${WS_NAME_LIST_TXT} ]]; then
        rm ${WS_NAME_LIST_TXT}
    fi
}

get_start_of_WS_name () {
    WS_START=$(awk '$0~/set \$ws1 / {print NR}' ${WS_NAME_CONFIG})
}

generate_name_list () {
    initialize
    get_start_of_WS_name
    readarray -s $(( ${WS_START} - 1 )) WS_NAME_CONFIG_ARRAY < ${WS_NAME_CONFIG}
    for i in ${!WS_NAME_CONFIG_ARRAY[@]}; do
        echo ${WS_NAME_CONFIG_ARRAY[$i]}
        echo ${WS_NAME_CONFIG_ARRAY[$i]} | cut -d' ' -f3 | tr -d '"' >> ${WS_NAME_LIST_TXT}
    done
}

# Main
generate_name_list
