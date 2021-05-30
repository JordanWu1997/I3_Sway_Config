#!/bin/bash

i3-msg [class="^.*"] border normal
i3-input -F "swap container with mark %s" -l 1 -P "Swapto: "
i3-msg [con_mark="^.*"] border pixel 1
