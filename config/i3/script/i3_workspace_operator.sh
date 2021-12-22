#!/usr/bin/env bash

# Swap workspace with i3-workspace-swap
# Installation: pip install i3-workspace-swap
i3-workspace-swap -d "$WPNM"

case $1 in
    "save_all")
        i3-resurrect save -w 1:A1
        i3-resurrect save -w 2:A2
        i3-resurrect save -w 3:A3
        i3-resurrect save -w 4:A4
        i3-resurrect save -w 5:A5
        i3-resurrect save -w 6:A6
        i3-resurrect save -w 7:A7
        i3-resurrect save -w 8:A8
        i3-resurrect save -w 9:A9
        i3-resurrect save -w 10:A10
        i3-resurrect save -w 11:B1
        i3-resurrect save -w 12:B2
        i3-resurrect save -w 13:B3
        i3-resurrect save -w 14:B4
        i3-resurrect save -w 15:B5
        i3-resurrect save -w 16:B6
        i3-resurrect save -w 17:B7
        i3-resurrect save -w 18:B8
        i3-resurrect save -w 19:B9
        i3-resurrect save -w 20:B10
        i3-resurrect save -w 21:C1
        i3-resurrect save -w 22:C2
        i3-resurrect save -w 23:C3
        i3-resurrect save -w 24:C4
        i3-resurrect save -w 25:C5
        i3-resurrect save -w 26:C6
        i3-resurrect save -w 27:C7
        i3-resurrect save -w 28:C8
        i3-resurrect save -w 29:C9
        i3-resurrect save -w 30:C10
        i3-resurrect save -w 31:D1
        i3-resurrect save -w 32:D2
        i3-resurrect save -w 33:D3
        i3-resurrect save -w 34:D4
        i3-resurrect save -w 35:D5
        i3-resurrect save -w 36:D6
        i3-resurrect save -w 37:D7
        i3-resurrect save -w 38:D8
        i3-resurrect save -w 39:D9
        i3-resurrect save -w 40:D10
        ;;
    "restore_all")
        i3-resurrect restore -w 1:A1
        i3-resurrect restore -w 2:A2
        i3-resurrect restore -w 3:A3
        i3-resurrect restore -w 4:A4
        i3-resurrect restore -w 5:A5
        i3-resurrect restore -w 6:A6
        i3-resurrect restore -w 7:A7
        i3-resurrect restore -w 8:A8
        i3-resurrect restore -w 9:A9
        i3-resurrect restore -w 10:A10
        i3-resurrect restore -w 11:B1
        i3-resurrect restore -w 12:B2
        i3-resurrect restore -w 13:B3
        i3-resurrect restore -w 14:B4
        i3-resurrect restore -w 15:B5
        i3-resurrect restore -w 16:B6
        i3-resurrect restore -w 17:B7
        i3-resurrect restore -w 18:B8
        i3-resurrect restore -w 19:B9
        i3-resurrect restore -w 20:B10
        i3-resurrect restore -w 21:C1
        i3-resurrect restore -w 22:C2
        i3-resurrect restore -w 23:C3
        i3-resurrect restore -w 24:C4
        i3-resurrect restore -w 25:C5
        i3-resurrect restore -w 26:C6
        i3-resurrect restore -w 27:C7
        i3-resurrect restore -w 28:C8
        i3-resurrect restore -w 29:C9
        i3-resurrect restore -w 30:C10
        i3-resurrect restore -w 31:D1
        i3-resurrect restore -w 32:D2
        i3-resurrect restore -w 33:D3
        i3-resurrect restore -w 34:D4
        i3-resurrect restore -w 35:D5
        i3-resurrect restore -w 36:D6
        i3-resurrect restore -w 37:D7
        i3-resurrect restore -w 38:D8
        i3-resurrect restore -w 39:D9
        i3-resurrect restore -w 40:D10
        ;;
    "single")
        # Calculate workspace number for different monitor
        case $2 in
            "A")
                ORIGIN=0
                ;;
            "B")
                ORIGIN=10
                ;;
            "C")
                ORIGIN=20
                ;;
            "D")
                ORIGIN=30
                ;;
            *)
                echo "Wrong Input Workspace Header (Available: A/B/C/D)"
        esac
        # Generate workspace name to swap
        WN=$(( $ORIGIN+$3 ))
        WPNM="$WN:$2$3"
        echo $WPNM
        # Swap workspace with i3-workspace-swap
        # Installation: pip install i3-workspace-swap
        i3-workspace-swap -d "$WPNM"
        ;;
    *)
    echo $0
esac
