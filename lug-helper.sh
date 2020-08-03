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

# Display a message to the user.  Expects a numerical argument followed by the string to display.
message() {
    if [ "$zenity" -eq 1 ]; then
            if [ "$1" -eq 1 ]; then
                # info
                margs="--info --no-wrap --text="
            elif [ "$1" -eq 2 ]; then
                # warning
                margs="--warning --no-wrap --text="
            elif [ "$1" -eq 3 ]; then
                # question
                margs="--question --text="
            elif [ "$1" -eq 4 ]; then
                # radio list
                margs="--list --radiolist --height=\"200\" --column=\" \" --column=\"What would you like to do?\" "
            elif [ "$1" -eq 5]; then
                # main menu radio list
                margs="--list --radiolist --height=\"175\" --text="Welcome, fellow penguin, to the Star Citizen Linux Users Group Helper Script!" --column=\" \" --column=\"What would you like to do?\" " 
            else
                echo -e "Invalid message format.\n\nThe message function expects a numerical argument followed by the string to display.\n"
                read -n 1 -s -p "Press any key..."
            fi

            # Display the message
            zenity "$margs$2" --icon-name='lutris' --width="400" --title="Star Citizen LUG Helper Script"
    else
        # Text based menu.  Does not work with message types 4 and 5 (zenity radio lists)
        # those need to be handled specially in the code
        if [ "$1" -eq 1 ]; then
            # info
            echo -e "\n$2\n"
            read -n 1 -s -p "Press any key..."
        elif [ "$1" -eq 2 ]; then
            # warning
            echo -e "\n$2\n" 
            read -n 1 -s -p "Press any key..."
            exit 0
        elif [ "$1" -eq 3 ]; then
            # question
            echo -e "\n$2\n" 
            while true; do
                read -p "[y/n]: " yn
                case "$yn" in
                    [Yy]*)
                          return 0
                          ;;
                    [Nn]*)
                          return 1
                          ;;
                    *)
                          echo "Please type 'y' or 'n'"
                          ;;
                 esac
            done
        else
            echo -e "Invalid message type.\n\nText menus are not compatible with message types 4 and 5 (zenity radio lists)\nand require special handling.\n"
            read -n 1 -s -p "Press any key..."
        fi
    fi
}

# Save exported keybinds, wipe the USER directory, and restore keybinds
sanitize() {
    clear
    # Display a warning to modify the default variables
    if [ "$i_changed_these" = "false" ]; then
        message 2 "Before this script can do its job, please edit it to change the default\nStar Citizen paths to match your configuration!\n"
    else
	# Sanity checks
	if [ ! -d "$prefix" ]; then
	    message 2 "Invalid path:\n$prefix\nAborting."
	elif [ ! -d "$path" ]; then
	    message 2 "Invalid path:\n$path\nAborting."
	else
	    
	    # Prompt user to back up the current keybinds in the game
	    message 1 "Before proceeding, please be sure you have\nmade a backup of your Star Citizen keybinds!\nTo do this from within the game, go to\nOptions->Keybindings->Control Profiles->Save Control Settings\nGive it a name and save it to the backup location\nthat you specified in this script's variables."

	    # Check for exported keybind files
	    exported=0  # Default to none found
	    if [ ! -d "$mappings" ] || [ -z "$(ls -A $mappings)" ]; then
		message 1 "Warning: No exported keybindings found.  Keybinds will not be backed up!"
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
		message 1 "\nTo re-import your keybinds, select it in-game from the list:\nOptions->Keybindings->Control Profiles\n"
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

check_map_count() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        message 2 "As far as this script can detect, your system is not configured\nto allow Star Citizen to use more than ~8GB or memory.\n\nYou will most likely experience crashes."
    fi
}

# Check vm.max_map_count for the correct setting and let the user fix it if needed
set_map_count() {
    clear
    # If vm.max_map_count is already set, no need to do anything
    if [ "$(cat /proc/sys/vm/max_map_count)" -ge 16777216 ]; then
    	message 1 "vm.max_map_count is already set to the optimal value.  You're all set!"
	exit 0
    fi

    trap check_map_count EXIT

    if grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then  
	if message 3 "It looks like you already configured your system to work with Star Citizen, and saved the setting to persist across reboots. However, for some reason the persistence part did not work.\n\nFor now, would you like to enable the setting again until the next reboot?"; then
            pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
	fi
	exit 0
    fi
    
    once="Change setting until next reboot"
    persist="Change setting and persist after reboot"
    manual="Show me the commands; I'll handle it myself"

    if message 3 "Running Star Citizen requires changing a system setting.\n\nvm.max_map_count must be increased to at least 16777216 to avoid crashes in areas with lots of geometry.\n\nAs far as this script can detect, the setting has not been changed on your system.\n\nWould you like to change the setting now?"; then
        if [ "$zenity" -eq 1 ]; then
            # zenity menu
            RESULT="$(message 4 "TRUE $once \ FALSE $persist \ FALSE $manual")"
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
                	    message 1 "To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl -p'"
        		else
                	    message 1 "To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"
        		fi
        		# Anyone who wants to do it manually doesn't need another warning
        		trap - EXIT
        		;;
                *)
        		echo "Dialog canceled or unknown option selected: $RESULT"
        		;;
        	esac
        else
            # text menu
            options="($once $persist $manual)"
            PS3="Enter selection number or 'q' to quit: "

            select choice in "${options[@]}"
            do
                case "$REPLY" in
                    "1")
                		pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
                                break
                		;;
                    "2")
                		if [ -d "/etc/sysctl.d" ]; then
                        	    pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.d/20-max_map_count.conf && sysctl -p'
                		else
                                    pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p'
                		fi
                                break
                		;;
                    "3")
                		if [ -d "/etc/sysctl.d" ]; then
                        	    message 1 "To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl -p'"
                		else
                        	    message 1 "To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"
                		fi
                		# Anyone who wants to do it manually doesn't need another warning
                		trap - EXIT
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
    fi
}

############################################################################
# MAIN
############################################################################

# Use Zenity if it is available
if [ "$zenity" -eq 1 ]; then
    check="Check my system settings for optimal performance"
    clean="Delete my USER folder and preserve my keybinds"
    options="$(message 5 "TRUE $check \ FALSE $clean")"

    case "$options" in
	"$check")
	    set_map_count
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
	case "$REPLY" in
	    "1")
		echo -e "\n"
		set_map_count
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
