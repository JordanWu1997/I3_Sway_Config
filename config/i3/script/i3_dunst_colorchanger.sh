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

# Template for monochrome color style
dunst -lf  "${color7:-#ffffff}" \
      -lb  "${color1:-#000000}" \
      -lfr "${color4:-#2e9ef4}" \
      -nf  "${color7:-#ffffff}" \
      -nb  "${color1:-#000000}" \
      -nfr "${color4:-#2e9ef4}" \
      -cf  "${color7:-#ffffff}" \
      -cb  "${color1:-#000000}" \
      -cfr "${color4:-#2e9ef4}" > /dev/null 2>&1 &

## Template for non-monochrome color style
#dunst -lf  "${color0:-#ffffff}" \
      #-lb  "${color1:-#000000}" \
      #-lfr "${color4:-#2e9ef4}" \
      #-nf  "${color0:-#ffffff}" \
      #-nb  "${color1:-#000000}" \
      #-nfr "${color4:-#2e9ef4}" \
      #-cf  "${color0:-#ffffff}" \
      #-cb  "${color1:-#000000}" \
      #-cfr "${color4:-#2e9ef4}" > /dev/null 2>&1 &
