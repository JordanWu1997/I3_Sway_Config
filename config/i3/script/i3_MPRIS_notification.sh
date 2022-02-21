#!/usr/bin/env bash

SONG=$(playerctl metadata --format "Title: {{ title }}\nArtist: {{ artist }}\nAlbum: {{ album }}")
notify-send -u low "MPRIS" "$SONG"
