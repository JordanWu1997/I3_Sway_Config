#!/usr/bin/env bash

kill $(ps -aux | grep "python3 $I3_BIN/i3-automark.py")
