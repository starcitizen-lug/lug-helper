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
# To export your keybinds from within the game, go to
# Options->Keybindings->Control Profiles->Save Control Settings
#
############################################################################

wine_conf="winedir.conf"
game_conf="gamedir.conf"
backup_conf="backupdir.conf"

# Use the XDG config directory if defined
if [ -z "$XDG_CONFIG_HOME" ]; then
    conf_dir="$HOME/.config"
    echo "DEBUG: XDG DIR NOT FOUND"
else
    conf_dir="$XDG_CONFIG_HOME"
    echo "DEBUG: XDG DIR FOUND"
fi

conf_subdir="starcitizen-lug"

############################################################################
############################################################################


# Display a message to the user.  Expects a numerical argument followed by the string to display.
message() {
    if [ "$has_zen" -eq 1 ]; then
        if [ "$1" -eq 1 ]; then
            # info
            margs=("--info" "--no-wrap" "--text=")
        elif [ "$1" -eq 2 ]; then
            # warning
            margs=("--warning" "--no-wrap" "--text=")
        elif [ "$1" -eq 3 ]; then
            # question
            margs=("--question" "--text=")
        elif [ "$1" -eq 4 ]; then
            # radio list
            margs=("--list" "--radiolist" "--height=200" "--column=" "--column=What would you like to do?")
        elif [ "$1" -eq 5 ]; then
            # main menu radio list
            margs=("--list" "--radiolist" "--height=175" "--text=Welcome, fellow penguin, to the Star Citizen LUG Helper Script!" "--column=" "--column=What would you like to do?")
        else
            echo -e "Invalid message format.\n\nThe message function expects a numerical argument followed by the string to display.\n"
            read -n 1 -s -p "Press any key..."
        fi

        # Display the message
	if [ "$1" -eq 4 ] || [ "$1" -eq 5 ]; then
	    # requires a space between the assembled arguments
	    shift 1   # drop the first numerical argument and shift the remaining up one
	    zenity "${margs[@]}" "$@" --width="400" --title="Star Citizen LUG Helper Script"
	else
	    # no space between the assmebled arguments
	    shift 1   # drop the first numerical argument and shift the remaining up one
	    zenity "${margs[@]}""$@" --width="400" --title="Star Citizen LUG Helper Script"
	fi
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
            echo -e "$2" 
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

# Get paths to the user's wine prefix, game directory, and a backup directory
getdirs() {
    # Sanity checks
    if [ ! -d "$conf_dir" ]; then
	message 2 "Invalid config path:\n$conf_dir\nAborting."
        exit 0
    fi

    if [ ! -d "$conf_dir/$conf_subdir" ]; then
        mkdir "$conf_dir/$conf_subdir"
    fi

    # Check if the config files already exist
    if [ -f "$conf_dir/$conf_subdir/$wine_conf" ]; then
        found_wine_conf=1
        wine_prefix="$(cat $conf_dir/$conf_subdir/$wine_conf")"
    fi
    if [ -f "$conf_dir/$conf_subdir/$game_conf" ]; then
        found_game_conf=1
        game_path="$(cat $conf_dir/$conf_subdir/$game_conf")"
    fi
    if [ -f "$conf_dir/$conf_subdir/$backup_conf" ]; then
        found_backup_conf=1
        backup_path="$(cat $conf_dir/$conf_subdir/$backup_conf")"
    fi
        
    if [ -z "$found_wine_config" ] || [ -z "$found_game_conf" ] || [ -z "$found_backup_conf" ]; then
    message 1 "You will now be asked to provide some directories needed by this script.\nThey will be saved for later use in:\n$conf_dir/$conf_subdir/"
    if [ "$has_zen" -eq 1 ]; then
        # Get the wine prefix directory
        if [ -z "$found_wine_conf" ]; then
            wine_prefix="$(zenity --file-selection --directory --title="Select your WINE prefix directory" --filename="$HOME/")"
	    if [ "$?" -eq -1 ]; then
                message 2 "An unexpected error has occurred."
            fi
        fi

        # Get the game path
        if [ -z "$found_game_conf" ]; then
            while true; do
                game_path="$(zenity --file-selection --directory --title="Select your Star Citizen LIVE directory" --filename="$prefix/")"
	        if [ "$?" -eq -1 ]; then
	            message 2 "An unexpected error has occurred."
                fi

                if [ "$(basename $game_path)" != "LIVE" ]; then
                    message 2 "You must select your LIVE directory."
                else
                    break
                fi
            done
        fi

        # Get the backup directory
        if [ -z "$found_backup_conf" ]; then
            backup_path="$(zenity --file-selection --directory --title="Select a backup directory for your keybinds" --filename="$HOME/")"
            if [ "$?" -eq -1 ]; then
	        message 2 "An unexpected error has occurred."
            fi
        fi
    else
	clear

        # Get the wine prefix directory
        if [ -z "$found_wine_conf" ]; then
	echo -e "Enter the full path to your WINE prefix directory"
	echo -e "ie. /home/USER/.wine/"
	while read -rp ": " wine_prefix; do
	    if [ ! -d "$wine_prefix" ]; then
		echo -e "That directory is invalid or does not exist. Please try again.\n"
	    else
		break
	    fi
	done

        # Get the game path
        if [ -z "$found_game_conf" ]; then
            echo -e "\nEnter the full path to your Star Citizen installation LIVE directory"
            echo -e "ie. /home/USER/.wine/drive_c/Program Files/Roberts Space Industries/Star Citizen/LIVE/"
            while read -rp ": " game_path; do
	        if [ ! -d "$game_path" ]; then
                    echo -e "That directory is invalid or does not exist. Please try again.\n"
                elif [ "$(basename $game_path)" != "LIVE" ]; then
                    echo -e "You must select your LIVE directory."
                else
		    break
	        fi
            done
        fi

        # Get the backup directory
        if [ -z "$found_backup_conf" ]; then
	    echo -e "\nEnter the full path to a backup directory for your keybinds"
            echo -e "ie. /home/USER/backups/"
            while read -rp ": " backup_path; do
	        if [ ! -d "$backup_path" ]; then
                    echo -e "That directory is invalid or does not exist. Please try again.\n"
                else
		    break
                fi
            done
        fi
    fi
    
        # Save the paths for later use
        echo "$wine_prefix" > "$conf_dir/$conf_subdir/$wine_conf"
        echo "$game_path" > "$conf_dir/$conf_subdir/$game_conf"
        echo "$backup_path" > "$conf_dir/$conf_subdir/$backup_conf"
    fi

    # Set some remaining directory paths
    user_dir="$game_path/USER"
    mappings_dir="$user_dir/Controls/Mappings"
}

# Save exported keybinds, wipe the USER directory, and restore keybinds
sanitize() {
    clear
		    
	    # Prompt user to back up the current keybinds in the game
	    message 1 "Before proceeding, please be sure you have\nexported your Star Citizen keybinds from within the game!\n\nTo do this, launch the game and go to:\nOptions->Keybindings->Control Profiles->Save Control Settings"

	    # Get/Set directory paths
	    getdirs

	    # Check for exported keybind files
	    exported=0  # Default to none found
	    if [ ! -d "$mappings_dir" ] || [ -z "$(ls -A $mappings_dir)" ]; then
		message 1 "Warning: No exported keybindings found.  Keybinds will not be backed up!"
		exported=0
	    else
		exported=1
	    fi

	    # Back up keybinds
	    if [ "$exported" -eq 1 ]; then
		echo "Backing up all saved keybinds..."
		mkdir -p "$backup_path" && cp -r "$mappings_dir/." "$backup_path/"
		echo -e "Done.\n"
	    fi
	    
	    # Wipe the user directory
	    echo "Wiping USER directory..."
	    rm -rf "$user_dir"
	    echo -e "Done.\n"

	    # Restore custom keybinds
	    if [ "$exported" -eq 1 ]; then
		echo "Restoring keybinds..."
		mkdir -p "$mappings_dir" && cp -r "$backup_path/." "$mappings_dir/"
		echo -e "Done.\n"
		message 1 "\nTo re-import your keybinds, select it in-game from the list:\nOptions->Keybindings->Control Profiles\n"
	    fi

    message 1 "Your USER directory has been cleaned up!"
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

    if message 3 "Running Star Citizen requires changing a system setting.\n\nvm.max_map_count must be increased to at least 16777216\nto avoid crashes in areas with lots of geometry.\n\nAs far as this script can detect, the setting\nhas not been changed on your system.\n\nWould you like to change the setting now?"; then
        if [ "$has_zen" -eq 1 ]; then
            # zenity menu
            list=("TRUE" "$once" "FALSE" "$persist" "FALSE" "$manual")
            RESULT="$(message 4 "${list[@]}")"
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
	    echo -e "\n"
            options=("$once" "$persist" "$manual")
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
			clear
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
clear

# Check if Zenity is available
has_zen=0
if [ -x "$(command -v zenity)" ]; then
    has_zen=0
fi

# Use Zenity if it is available
if [ "$has_zen" -eq 1 ]; then
    check="Check vm.max_map_count for optimal performance"
    clean="Delete my USER folder and preserve my keybinds"
    list=("TRUE" "$check" "FALSE" "$clean" "FALSE" "test")

    options="$(message 5 "${list[@]}")"
    case "$options" in
	"$check")
	    set_map_count
	    ;;
	"$clean")
	    sanitize
	    ;;
	"test")
	    getdirs
	    echo "$prefix"
	    echo "$path"
	    echo "$backups"
	    ;;
	*)
	    ;;
    esac
else
    # Use a text menu if Zenity is not available
    echo -e "\nWelcome, fellow penguin, to the Star Citizen Linux Users Group Helper Script!\nWhat would you like to do?\n"

    options=("Check vm.max_map_count for optimal performance" "Delete my USER folder and preserve my keybinds")
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
	    "3")
		echo -e "\n"
		getdirs
		echo "$prefix"
		echo "$path"
		echo "$backups"
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
