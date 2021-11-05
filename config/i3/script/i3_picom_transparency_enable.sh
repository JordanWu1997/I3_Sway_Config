#!/usr/bin/env bash

kill $(ps -aux | grep "/usr/local/bin/picom")
/usr/local/bin/picom --config ${HOME}/.config/picom/picom_transparency.conf
