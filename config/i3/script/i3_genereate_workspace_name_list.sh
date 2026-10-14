#!/usr/bin/env bash

# i3 workspace name config file
WS_NAME_CONFIG="$HOME/.config/i3/config.d/i3_workspace_name.config"

# workspace name list text file for rofi selector
WS_NAME_LIST_TXT="$HOME/.config/i3/share/i3_workspace_name_list.txt"

generate_name_list () {
    sed -nE 's/^[[:space:]]*set[[:space:]]+[$]ws[0-9]+[[:space:]]+"([^"]*)".*$/\1/p' \
        "$WS_NAME_CONFIG" > "$WS_NAME_LIST_TXT"
}

# Main
generate_name_list
