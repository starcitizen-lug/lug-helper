#!/bin/bash

#############################################################################
#
# Star Citizen's Linux Users Group presents:
# A Simple Star Citizen Housekeeping Script!
#
# Edit the paths below to match your configuration,
# then run this script whenever you update Star Citizen.
# It will automate some housekeeping tasks for you!
#
# This script will save any keybinds you have exported from within the game,
# wipe the USER directory, and then restore your keybinds.
#
# To export your keybinds from within the game, go to
# Options->Keybindings->Control Profiles->Save Control Settings
# Give it a name and save it in the backup location you specify below.
#
# To re-import them, select the keybind file from that same list.
#
# 
# Written by
# https://robertsspaceindustries.com/citizens/theSane
#############################################################################

# Change these paths
i_changed_these="false"  # Change this to true once you make your edits
prefix="$HOME/.wine"
path="$prefix/drive_c/Program Files/Roberts Space Industries/Star Citizen/LIVE"
backups="$HOME/Documents/Star Citizen"

# You shouldn't need to change these
user="$path/USER"
mappings="$user/Controls/Mappings"

#############################################################################
#############################################################################

# Display a warning to modify the default variables
if [ "$i_changed_these" = "false" ]; then
    echo "Before you run this script, edit it and change"
    echo -e "the default paths to match your configuration!\n"
    read -n 1 -s -p "Press any key to continue, or Ctrl-c to quit..."
    echo -e "\n----------------------------------------------------------------\n"
fi

# Sanity checks
if [ ! -d "$prefix" ]; then
    echo "Invalid path: $prefix"
    echo "Aborting"
elif [ ! -d "$path" ]; then
    echo "Invalid path: $path"
    echo "Aborting"
else
   
    # Prompt user to back up the current keybinds in the game
    echo -e "\nBefore proceeding, please be sure you have"
    echo "made a backup of your Star Citizen keybinds!"
    echo -e "\nTo do this from within the game, go to"
    echo "Options->Keybindings->Control Profiles->Save Control Settings"
    echo -e "\nGive it a name and save it to the backup location"
    echo -e "that you specified in this script's variables\n"
    read -n 1 -s -p "Press any key to continue, or Ctrl-c to quit..."
    echo -e "\n----------------------------------------------------------------\n"

    # Check for exported keybind files
    exported=0  # Default to none found
    if [ ! -d "$mappings" ] || [ -z "$(ls -A $mappings)" ]; then
	echo "Warning: No exported keybindings found.  Keybinds will not be backed up!"
	exported=0
    else
	exported=1
    fi

    # Back up keybinds
    if [ "$exported" -eq 1 ]; then
	echo -e "\nBacking up all saved keybinds..."
	mkdir -p "$backups" && cp -r "$mappings/." "$backups/"
	echo "Done."
    fi
    
    # Wipe the user directory
    echo -e "\nWiping USER directory..."
    rm -rf "$user"
    echo "Done."

    # Restore custom keybinds
    if [ "$exported" -eq 1 ]; then
	echo -e "\nRestoring keybinds..."
	mkdir -p "$mappings" && cp -r "$backups/." "$mappings/"
	echo "Done."
	echo -e "\n*NOTE*"
	echo "To re-import your keybinds, select it in-game from the list:"
	echo "Options->Keybindings->Control Profiles"
    fi



    # Uncomment to wash Snagletooth's car
    #echo -e "\nWashing the car..."
    #echo -e "\nWorking at the car wash, yeah!"
    #echo "Come on and sing it with me, car wash!"
    #echo "Sing it with the feeling now, car wash yeah!"

    echo -e "\nAnd we're done here.  Have fun!"
fi
