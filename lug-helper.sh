#!/usr/bin/env sh

############################################################################
# Star Citizen's Linux Users Group Helper Script
############################################################################
#
# Greetings, fellow penguin!
#
#
# This script is designed to help you with some housekeeping tasks.
#
# It will check your system for optimal settings,
# allowing you to change them as needed to prevent game crashes.
#
#
# It also includes an easy way for you to wipe your USER folder
# whenever there is a major version update.  It will back up your
# exported keybinds, delete your USER folder, then restore your keybinds.
#
# Edit the default paths below to match your configuration.
#
#
# To export your keybinds from within the game, go to
# Options->Keybindings->Control Profiles->Save Control Settings
# Give it a name and save it in the backup location you specify below.
#
############################################################################

# Change these paths
i_changed_these="false"  # Change this to true once you make your edits
prefix="$HOME/.wine"
path="$prefix/drive_c/Program Files/Roberts Space Industries/Star Citizen/LIVE"
backups="$HOME/Documents/Star Citizen"

# You shouldn't need to change these
user="$path/USER"
mappings="$user/Controls/Mappings"

############################################################################
############################################################################

# Check if Zenity is available
zenity=0
if [ -x "$(command -v zenity)" ]; then
    zenity=1
fi

main_dialog(){
    zenity "$@" --icon-name='lutris' --width="400" --title="Star Citizen LUG Helper Script"
}

mem_dialog() {
    zenity "$@" --icon-name='lutris' --width="400" --title="Star Citizen memory requirements check"
}

# Save exported keybinds, wipe the USER directory, and restore keybinds
sanitize() {
    # Display a warning to modify the default variables
    if [ "$i_changed_these" = "false" ]; then
	if [ "$zenity" -eq 1 ]; then
	    main_dialog --info --text="Before you run this script, edit it and change the default Star Citizen paths to match your configuration!"
	else
	    echo "Before you run this script, edit it and change the default"
	    echo -e "Star Citizen paths to match your configuration!\n"
	    read -n 1 -s -p "Press any key to exit..."
	fi
    else
	# Sanity checks
	if [ ! -d "$prefix" ]; then
	    echo "Invalid path: $prefix"
	    echo "Aborting"
	elif [ ! -d "$path" ]; then
	    echo "Invalid path: $path"
	    echo "Aborting"
	else
	    
	    # Prompt user to back up the current keybinds in the game
	    echo "Before proceeding, please be sure you have"
	    echo -e "made a backup of your Star Citizen keybinds!\n"
	    echo "To do this from within the game, go to"
	    echo -e "Options->Keybindings->Control Profiles->Save Control Settings\n"
	    echo "Give it a name and save it to the backup location"
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
		echo "Backing up all saved keybinds..."
		mkdir -p "$backups" && cp -r "$mappings/." "$backups/"
		echo -e "Done.\n"
	    fi
	    
	    # Wipe the user directory
	    echo "Wiping USER directory..."
	    rm -rf "$user"
	    echo -e "Done.\n"

	    # Restore custom keybinds
	    if [ "$exported" -eq 1 ]; then
		echo "Restoring keybinds..."
		mkdir -p "$mappings" && cp -r "$backups/." "$mappings/"
		echo -e "Done.\n"
		echo "*NOTE*"
		echo "To re-import your keybinds, select it in-game from the list:"
		echo -e "Options->Keybindings->Control Profiles\n"
	    fi



	    # Special request:  Uncomment to wash Snagletooth's car
	    #echo -e "Washing the car...\n"
	    #echo "Working at the car wash, yeah!"
	    #echo "Come on and sing it with me, car wash!"
	    #echo -e "Sing it with the feeling now, car wash yeah!\n"

	    echo "And we're done here.  Have fun!"
	fi
    fi
}

final_check() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        mem_dialog --warning --text="As far as this script can detect, your system is not configured to allow Star Citizen to use more than ~8GB or memory.\n\nYou will most likely experience crashes."
    fi
}

# Check vm.max_map_count for the correct setting and let the user fix it if needed
mem_check() {
    # If vm.max_map_count is already set, no need to do anything
    if [ "$(cat /proc/sys/vm/max_map_count)" -ge 16777216 ]; then
    	main_dialog --info --text="vm.max_map_count is already set to the optimal value.  You're all set!"
	exit 0
    fi

    trap final_check EXIT

    if grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then  
	if mem_dialog --question --text="It looks like you already configured your system to work with Star Citizen, and saved the setting to persist across reboots. However, for some reason the persistence part did not work.\n\nFor now, would you like to enable the setting again until the next reboot?"; then
            pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
	fi
	exit 0
    fi
    
    once="Change setting until next reboot"
    persist="Change setting and persist after reboot"
    manual="Show me the commands; I'll handle it myself"

    if mem_dialog --question --text="Running Star Citizen requires changing a system setting.\n\nvm.max_map_count must be increased to at least 16777216 to avoid crashes in areas with lots of geometry.\n\nAs far as this script can detect, the setting has not been changed on your system.\n\nWould you like to change the setting now?"; then
	# I tried to embed the command in the dialog and run the output, but
	# parsing variables with embedded quotes is an excercise in frustration.
	RESULT="$(mem_dialog --list --radiolist --height="200" --column=" " --column="Command" "TRUE" "$once" \ "FALSE" "$persist" \ "FALSE" "$manual")"
	case "$RESULT" in
            "$once")
		pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
		;;
            "$persist")
		if [ -d "/etc/sysctl.d" ]; then
        	    pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.d/20-max_map_count.conf && sysctl -p'
		else
                    pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p'
		fi
		;;
            "$manual")
		if [ -d "/etc/sysctl.d" ]; then
            	    mem_dialog --info --no-wrap --text="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl -p'"
		else
            	    mem_dialog --info --no-wrap --text="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"
		fi
		# Anyone who wants to do it manually doesn't need another warning
		trap - EXIT
		;;
            *)
		echo "Dialog canceled or unknown option selected: $RESULT"
		;;
	esac
    fi
}

############################################################################
# MAIN
############################################################################

# Use Zenity if it is available
if [ "$zenity" -eq 1 ]; then
    check="Check my system settings for optimal performance"
    clean="Delete my USER folder and preserve my keybinds"
    options="$(main_dialog --height="175" --text="Welcome, fellow penguin, to the Star Citizen Linux Users Group Helper Script!" --list --radiolist --column=" " --column="What would you like to do?" "TRUE" "$check" \ "FALSE" "$clean")"

    case "$options" in
	"$check")
	    mem_check
	    ;;
	"$clean")
	    sanitize
	    ;;
	*)
	    ;;
    esac
else
# Use a text menu if Zenity is not available
    echo -e "\nWelcome, fellow penguin, to the Star Citizen Linux Users Group Helper Script!\nWhat would you like to do?\n"

    options=("Check my system settings for optimal performance" "Delete my USER folder and preserve my keybinds")
    PS3="Enter selection number or 'q' to quit: "

    select choice in "${options[@]}"
    do
	case $REPLY in
	    "1")
		echo -e "\n"
		mem_check
		break
		;;
	    "2")
		echo -e "\n"
		sanitize
		break
		;;
	    "q")
		break
		;;
	    *)
		echo -e "\nInvalid selection"
		continue
		;;
	esac
    done
fi
