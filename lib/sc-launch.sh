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
# IMPORTANT NOTE about using the above .desktop files:
# The RSI Launcher currently requires a terminal. Without this step, you will see a javascript error!
# To use the above .desktop files, modify the last line of this script as detailed in its comment
#
# If you do not wish to use the above .desktop files, then simply run this script from your terminal

# Configure the environment
# Add additional environment variables here as needed
export WINEPREFIX="$HOME/Games/star-citizen"
export EOS_USE_ANTICHEATCLIENTNULL=1
export DXVK_HUD=0
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=1073741824
export WINE_HIDE_NVIDIA_GPU=1
export radv_zero_vram="true"
#export MANGOHUD=1

# Launch the game
# If you wish to launch the game from the .desktop files as mentioned above,
# modify this line to open your preferred terminal and then call wine. For example:
#
# gnome-terminal -- sh -c 'wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"'
#
# If you do not wish to use the above .desktop files, then no modifications are required.
wine "C:\Program Files\Roberts Space Industries\RSI Launcher\RSI Launcher.exe"
