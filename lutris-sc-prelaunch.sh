#!/bin/sh
############################################
## Lutris pre-launch script for Star Citizen
############################################

## EAC Workaround: Remove EAC cache
EACDIR="$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/EasyAntiCheat"

if [ -d "$EACDIR" ]; then
    rm -rf "$EACDIR"
fi
