#!/bin/bash

killall picom
killall flashfocus
i3-msg restart
i3_automark_enable.sh
i3_dunst_colorchanger.sh
