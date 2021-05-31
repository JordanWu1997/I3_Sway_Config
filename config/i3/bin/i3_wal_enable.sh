#!/bin/bash

awk 'NR==2 {print $4}' ~/.fehbg | xargs -I{} wal -i {}
