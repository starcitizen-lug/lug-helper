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
# Running this script within your terminal or with the .desktop file helps prevent lingering background wine processes

# Configure the environment
# Add additional environment variables here as needed
export WINEPREFIX="$HOME/Games/star-citizen"
export EOS_USE_ANTICHEATCLIENTNULL=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=1073741824
export radv_zero_vram="true"
#export DXVK_HUD=fps,compiler
#export MANGOHUD=1

# Run optional prelaunch and postexit scripts
# To use, update the game install paths here, then create the scripts with your desired actions in them
#
# "$HOME/Games/star-citizen/sc-prelaunch.sh"
# trap "$HOME/Games/star-citizen/sc-postexit.sh" EXIT

# Launch the game
#
# To enable feral gamemode, replace the launch line below with:
# gamemoderun wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
#
# To enable gamescope and feral gamemode, replace the launch line below with the desired gamescope arguments. For example:
# gamescope --hdr-enabled -W 2560 -H 1440 --force-grab-cursor gamemoderun wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"

wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
