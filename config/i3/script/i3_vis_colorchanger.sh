#!/usr/bin/env bash
# Generates vis colour file

# source the current wal colour scheme
source $HOME/.cache/wal/colors.sh

# assign the variables in the wal scheme in vis' format
cat > $HOME/.config/vis/colors/wal <<CONF
$color1
$color2
$color3
$color4
$color5
$color6
$color7
$color8
$color9
$color10
$color11
$color12
CONF

# reload vis' config
killall -USR1 vis
