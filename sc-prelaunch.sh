#!/bin/sh

EACDIR="$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat"

if [ -d "$EACDIR" ]; then
    rm -rf "$EACDIR"
fi