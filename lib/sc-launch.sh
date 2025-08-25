#!/usr/bin/env bash

################################################################################
# This script launches Star Citizen using Wine.
# It is meant to be used after installation via the LUG Helper.
#
# The following .desktop files are added by wine during installation and then
# modified by the LUG Helper to call this script.
# They are automatically detected by most desktop environments for easy game
# launching.
#
################################################################################
# $HOME/Desktop/RSI Launcher.desktop
# $HOME/.local/share/applications/wine/Programs/Roberts Space Industries/RSI Launcher.desktop
################################################################################
#
# If you do not wish to use the above .desktop files, simply run this script
# from your terminal.
#
# version: 1.8
################################################################################

################################################################
# Configure the environment
# Add additional environment variables here as needed
################################################################
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

################################################################
# Configure the wine binaries to be used
#
# To use a custom wine runner, set the path to its bin directory
# export wine_path="/path/to/custom/runner/bin"
################################################################
export wine_path="$(command -v wine | xargs dirname)"

#############################################
# Command line arguments
#############################################
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
        /usr/bin/env bash --norc -c "${wine_path}/winecfg"; exit 0
        ;;
    "controllers")
        /usr/bin/env bash --norc -c "${wine_path}/wine control joy.cpl"; exit 0
        ;;
esac

#############################################
# It's a trap!
#############################################
# Kill the wine prefix when this script exits
# This makes sure there will be no lingering background wine processes
update_check() {
    while "$wine_path"/winedbg --command "info proc" | grep -qi "rsi.*setup"; do
        sleep 2
    done
}
trap "update_check; \"$wine_path\"/wineserver -k" EXIT

#############################################
# Launch the game
#############################################
# To enable feral gamemode, replace the launch line below with:
# gamemoderun "$wine_path"/wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe" > "$launch_log" 2>&1
#
# To enable gamescope and feral gamemode, replace the launch line below with the
# desired gamescope arguments. For example:
# gamescope --hdr-enabled -W 2560 -H 1440 --force-grab-cursor gamemoderun "$wine_path"/wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe" > "$launch_log" 2>&1

"$wine_path"/wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe" > "$launch_log" 2>&1
