#!/usr/bin/env bash

NOTIFY_ID=19970920
printf -v BACKLIGHT "%0.0f" $(xbacklight)
dunstify -r $NOTIFY_ID --urgency low --appname="Backlight" --icon=~/.config/i3/share/lightbulb_icon.png "$BACKLIGHT%"
