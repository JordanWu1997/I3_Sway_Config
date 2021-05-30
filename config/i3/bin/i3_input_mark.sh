#!/bin/bash

i3-msg [class="^.*"] border normal
i3-input -F "mark %s" -l 1 -P "Mark: "
i3-msg [con_mark="^.*"] border pixel 1
