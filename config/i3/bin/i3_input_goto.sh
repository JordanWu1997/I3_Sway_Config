#!/bin/bash

i3-msg [class="^.*"] border normal
i3-input -F "[con_mark=%s] focus" -l 1 -P "Goto: "
i3-msg [con_mark="^.*"] border pixel 1
