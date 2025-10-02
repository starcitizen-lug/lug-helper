#!/usr/bin/env bash

# This script launches Star Citizen using Wine.
# It is meant to be used after installation via the LUG Helper.
#
# Usage:
# Run from your terminal or use the .desktop files installed by the Helper.
#
# version: 1.9

############################################################################
# ENVIRONMENT VARIABLES
############################################################################
# Add additional environment variables to this section as needed
# Example:
# export NEW_VARIABLE="value"
############################################################################
export WINEPREFIX="$HOME/Games/star-citizen"

launch_log="$WINEPREFIX/sc-launch.log"
export WINEDLLOVERRIDES=winemenubuilder.exe=d # Prevent updates from overwriting our .desktop entries
export WINEDEBUG=-all # Cut down on console debug messages
# Nvidia cache options
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=10737418240
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX"
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
# Mesa (AMD/Intel) shader cache options
export MESA_SHADER_CACHE_DIR="$WINEPREFIX"
export MESA_SHADER_CACHE_MAX_SIZE="10G"
# Performance options
export WINEESYNC=1
export WINEFSYNC=1
# Optional HUDs
#export DXVK_HUD=fps,compiler
#export MANGOHUD=1

############################################################################
# END ENVIRONMENT VARIABLES
############################################################################

##################
# Wine binary path
##################
# To use a custom wine runner, set the path to its bin directory
# export wine_path="/path/to/custom/runner/bin"
export wine_path="$(command -v wine | xargs dirname)"

########################
# Command line arguments
########################
# shell - Drop into a Wine maintenance shell
# config - Wine configuration
# controllers - Game controller configuration
# Usage: ./sc-launch.sh shell
case "$1" in
    "shell")
        echo "Entering Wine prefix maintenance shell. Type 'exit' when done."
        export PATH="$wine_path:$PATH"; export PS1="Wine: "
        cd "$WINEPREFIX"; pwd; /usr/bin/env bash --norc; exit 0
        ;;
    "config")
        /usr/bin/env bash --norc -c "\"${wine_path}\"/winecfg"; exit 0
        ;;
    "controllers")
        /usr/bin/env bash --norc -c "\"${wine_path}\"/wine control joy.cpl"; exit 0
        ;;
esac

##########################
# Update check and cleanup
##########################
# Kill existing wine processes before launch
update_check() {
    while "$wine_path"/winedbg --command "info proc" | grep -qi "rsi.*setup"; do
        echo "RSI Setup process detected. Exiting."; exit 0
    done
}
"$wine_path"/wineserver -k

############################################################################
# Launch the game
############################################################################
"$wine_path"/wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe" > "$launch_log" 2>&1
