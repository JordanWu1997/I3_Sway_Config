#!/usr/bin/env bash
# Ported from i3_genereate_workspace_name_list.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config.d/i3_workspace_name.config -> ~/.config/sway/config.d/sway_workspace_name.config
#   output ~/.config/i3/share/i3_workspace_name_list.txt
#       -> ~/.config/i3/share/sway_workspace_name_list.txt (sway-specific, so the
#          i3 and sway lists do not overwrite each other when names differ)
# Readers on sway: sway_rofi_omnisearch.sh (Workspaces), and sway ports of
# i3_workspace_operator.sh / i3_new_workspace.sh should read the same file.

# sway workspace name config file
WS_NAME_CONFIG="$HOME/.config/sway/config.d/sway_workspace_name.config"

# workspace name list text file for rofi selector
WS_NAME_LIST_TXT="$HOME/.config/i3/share/sway_workspace_name_list.txt"

generate_name_list () {
    sed -nE 's/^[[:space:]]*set[[:space:]]+[$]ws[0-9]+[[:space:]]+"([^"]*)".*$/\1/p' \
        "$WS_NAME_CONFIG" > "$WS_NAME_LIST_TXT"
}

# Main
generate_name_list
