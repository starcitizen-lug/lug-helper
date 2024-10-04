#!/usr/bin/env bash

# This script configures and launches Star Citizen
# It is installed by the LUG Helper when the game is installed with Wine (not Lutris)
#
# The following .desktop files are added by wine during installation and then modified by the LUG Helper to call this script
# They are automatically detected by most desktop environments for easy game launching
#
#############################################################################################
# $HOME/Desktop/RSI Launcher.desktop
# $HOME/.local/share/applications/wine/Programs/Roberts Space Industries/RSI Launcher.desktop
#############################################################################################
#
# If you do not wish to use the above .desktop files, then simply run this script from your terminal


#####################################################
# Configure the environment
# Add additional environment variables here as needed
#####################################################
export WINEPREFIX="$HOME/Games/star-citizen"
export WINEDLLOVERRIDES=winemenubuilder.exe=d # Prevent updates from overwriting our .desktop entries
#export EOS_USE_ANTICHEATCLIENTNULL=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=1073741824
# Extra Nvidia cache options
#export __GL_SHADER_DISK_CACHE_PATH="/path/you/want/for/your/cache"
#export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=true
#export DXVK_HUD=fps,compiler
#export MANGOHUD=1

#############################################
# Run optional prelaunch and postexit scripts
#############################################
# To use, update the game install paths here, then create the scripts with your desired actions in them
# Replace the trap line below with the one provided here
#
# "$HOME/Games/star-citizen/sc-prelaunch.sh"
# trap "wineserver -k; $HOME/Games/star-citizen/sc-postexit.sh" EXIT

# Kill the wine prefix when this script exits
# This makes sure there will be no lingering background wine processes
trap "wineserver -k" EXIT

#################
# Launch the game
#################
# To enable feral gamemode, replace the launch line below with:
# gamemoderun wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
#
# To enable gamescope and feral gamemode, replace the launch line below with the desired gamescope arguments. For example:
# gamescope --hdr-enabled -W 2560 -H 1440 --force-grab-cursor gamemoderun wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
#
# To use a custom wine runner, simply call its binary
# /path/to/custom/runner/bin/wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"

wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
