#!/bin/sh

#        -lf/nf/cf color
#            Defines the foreground color for low, normal and critical notifications respectively.
#
#        -lb/nb/cb color
#            Defines the background color for low, normal and critical notifications respectively.
#
#        -lfr/nfr/cfr color
#            Defines the frame color for low, normal and critical notifications respectively.

[ -f "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

pidof dunst && killall dunst

dunst -lf  "${color0:-#ffffff}" \
      -lb  "${color1:-#000000}" \
      -lfr "${color2:-#2e9ef4}" \
      -nf  "${color3:-#ffffff}" \
      -nb  "${color4:-#000000}" \
      -nfr "${color5:-#2e9ef4}" \
      -cf  "${color6:-#ffffff}" \
      -cb  "${color7:-#000000}" \
      -cfr "${color8:-#2e9ef4}" > /dev/null 2>&1 &
