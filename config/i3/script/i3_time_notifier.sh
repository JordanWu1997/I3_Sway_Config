#!/usr/bin/env bash

NOTIFY_ID=97092019

notify-send -t 1500 -r ${NOTIFY_ID} -a "Current Time" $(date +"%R")
