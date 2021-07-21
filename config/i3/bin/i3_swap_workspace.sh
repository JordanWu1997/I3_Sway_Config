#!/bin/bash

# Calculate workspace number for different monitor
if [ $1 == "A" ]; then
    ORIGIN=0
elif [ $1 == "B" ]; then
    ORIGIN=10
elif [ $1 == "C" ]; then
    ORIGIN=20
elif [ $1 == "D" ]; then
    ORIGIN=30
else
    echo "Wrong Input Workspace Header (Available: A/B/C/D)"
fi

# Generate workspace name to swap
WN=$(( $ORIGIN+$2 ))
WPNM="$WN:$1$2"
echo $WPNM

# Swap workspace with i3-workspace-swap
# Installation: pip install i3-workspace-swap
i3-workspace-swap -d "$WPNM"
