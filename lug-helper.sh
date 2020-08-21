#!/usr/bin/env sh

############################################################################
# Star Citizen's Linux Users Group Helper Script
############################################################################
#
# Greetings, fellow Penguin!
#
#
# This script is designed to help you optimize your system to run
# Star Citizen as smoothly as possible.
#
# It presents options to check your system for optimal settings
# and helps you change them as needed to prevent game crashes.
#
#
# It also includes an easy way for you to wipe your USER folder
# as is recommended after major version updates.
# It will back up your exported keybinds, delete your USER folder,
# then restore your keybinds.
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
else
    conf_dir="$XDG_CONFIG_HOME"
fi

conf_subdir="starcitizen-lug"
############################################################################
############################################################################


# Display a message to the user.  Expects a numerical argument to indicate the message type,
# followed by a string of arguments that will be passed to zenity or echoed to the user.
#
# To call this function, use the following format: message [number] [string]
# See the message types below for specific instructions on formatting the string.
message() {
    if [ "$has_zen" -eq 1 ]; then
        case "$1" in
	    1)
		# info message
		# call format: message 1 "text to display"
		margs=("--info" "--no-wrap" "--text=")
		;;
            2)
		# warning message
		# call format: message 2 "text to display"
		margs=("--warning" "--text=")
		;;
            3)
		# question
		# call format: message 3 "question to ask?"
		margs=("--question" "--text=")
		;;
            4)
		# radio button list
		# call format: message 4 "--height=165" "TRUE" "List item 1" "FALSE" "List item 2" "FALSE" "List item 3"
		# IMPORTANT: When calling, specify an appropriate height for the dialog based on the number of items in your list
		margs=("--list" "--radiolist" "--text=Choose from the following options:" "--hide-header" "--column=" "--column=Option")
		;;
            5)
		# main menu radio list
		# call format: message 5 "TRUE" "List item 1" "FALSE" "List item 2" "FALSE" "List item 3"
		# IMPORTANT: Adjust the height value below based on the number of items listed in the menu
		margs=("--list" "--radiolist" "--height=290" "--text=<b><big>Welcome, fellow Penguin, to the Star Citizen LUG Helper!</big>\n\nThis helper is designed to help optimize your system for Star Citizen</b>\n\nYou may choose from the following options:" "--hide-header" "--column=" "--column=Option")
		;;
	    *)
		echo -e "Invalid message format.\n\nThe message function expects a numerical argument followed by string arguments.\n"
		read -n 1 -s -p "Press any key..."
		;;
        esac

        # Display the message
	if [ "$1" -eq 4 ] || [ "$1" -eq 5 ]; then
	    # requires a space between the assembled arguments
	    shift 1   # drop the first numerical argument and shift the remaining up one
	    zenity "${margs[@]}" "$@" --width="400" --title="Star Citizen LUG Helper"
	else
	    # no space between the assmebled arguments
	    shift 1   # drop the first numerical argument and shift the remaining up one
	    zenity "${margs[@]}""$@" --width="400" --title="Star Citizen LUG Helper"
	fi
    else
        # Text based menu.  Does not work with message types 4 and 5 (zenity radio lists)
        # those need to be handled specially in the code
        case "$1" in
	    1)
		# info message
		# call format: message 1 "text to display"
		clear
		echo -e "\n$2\n"
		read -n 1 -s -p "Press any key..."
		;;
            2)
		# warning message
		# call format: message 2 "text to display"
		clear
		echo -e "\n$2\n" 
		read -n 1 -s -p "Press any key..."
		return 0
		;;
            3)
		# question
		# call format: message 3 "question to ask?"
		clear
		echo -e "$2" 
		while read -p "[y/n]: " yn; do
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
		;;
	    *)
		echo -e "\nInvalid message type.\n\nText menus are not compatible with message types 4 and 5 (zenity radio lists)\nand require special handling.\n"
		read -n 1 -s -p "Press any key..."
		;;
        esac
    fi
}

# Get paths to the user's wine prefix, game directory, and a backup directory
getdirs() {
    # Sanity checks
    if [ ! -d "$conf_dir" ]; then
	message 2 "Config directory not found. The helper is unable to proceed.\n\n$conf_dir"
        return 1
    fi

    if [ ! -d "$conf_dir/$conf_subdir" ]; then
        mkdir "$conf_dir/$conf_subdir"
    fi

    # Check if the config files already exist
    if [ -f "$conf_dir/$conf_subdir/$wine_conf" ]; then
        wine_prefix="$(cat "$conf_dir/$conf_subdir/$wine_conf")"
    fi
    if [ -f "$conf_dir/$conf_subdir/$game_conf" ]; then
        game_path="$(cat "$conf_dir/$conf_subdir/$game_conf")"
	if [ "$(basename "$game_path")" != "Star Citizen" ]; then
	    echo -e "\nUnexpected game path found in config file, ignoring.\n"
	    game_path=""
	fi
    fi
    if [ -f "$conf_dir/$conf_subdir/$backup_conf" ]; then
        backup_path="$(cat "$conf_dir/$conf_subdir/$backup_conf")"
    fi
    
    if [ -z "$wine_prefix" ] || [ -z "$game_path" ] || [ -z "$backup_path" ]; then
	message 1 "You will now be asked to provide some directories needed by the helper.\n\nThey will be saved for later use in:\n$conf_dir/$conf_subdir/"
	if [ "$has_zen" -eq 1 ]; then
            # Get the wine prefix directory
            if [ -z "$wine_prefix" ]; then
		wine_prefix="$(zenity --file-selection --directory --title="Select your WINE prefix directory" --filename="$HOME/.wine")"
		if [ "$?" -eq -1 ]; then
                    message 2 "An unexpected error has occurred. The helper is unable to proceed."
		    return 1
		elif [ -z "$wine_prefix" ]; then
		    # User clicked cancel
		    message 2 "Operation cancelled.\nNo changes have been made to your game."
		    return 1
		fi
            fi

            # Get the game path
            if [ -z "$game_path" ]; then
		while game_path="$(zenity --file-selection --directory --title="Select your Star Citizen directory" --filename="$wine_prefix/drive_c/Program Files/Roberts Space Industries/Star Citizen")"; do
	            if [ "$?" -eq -1 ]; then
			message 2 "An unexpected error has occurred. The helper is unable to proceed."
			return 1
                    elif [ "$(basename "$game_path")" != "Star Citizen" ]; then
			message 2 "You must select the directory named 'Star Citizen'"
		    else
			# All good or cancel
			break
                    fi
		done
		
		if [ -z "$game_path" ]; then
		    # User clicked cancel
		    message 2 "Operation cancelled.\nNo changes have been made to your game."
		    return 1
		fi
            fi

            # Get the backup directory
            if [ -z "$backup_path" ]; then
		backup_path="$(zenity --file-selection --directory --title="Select a backup directory for your keybinds" --filename="$HOME/")"
		if [ "$?" -eq -1 ]; then
	            message 2 "An unexpected error has occurred. The helper is unable to proceed."
		    return 1
		elif [ -z "$backup_path" ]; then
		    # User clicked cancel
		    message 2 "Operation cancelled.\nNo changes have been made to your game."
		    return 1
		fi
            fi
	else
	    clear
            # Get the wine prefix directory
            if [ -z "$wine_prefix" ]; then
		echo -e "Enter the full path to your WINE prefix directory (case sensitive)"
		echo -e "ie. /home/USER/.wine/"
		while read -rp ": " wine_prefix; do
		    if [ ! -d "$wine_prefix" ]; then
			echo -e "That directory is invalid or does not exist. Please try again.\n"
		    else
			break
		    fi
		done

		# Get the game path
		if [ -z "$game_path" ]; then
		    echo -e "\nEnter the full path to your Star Citizen installation directory\n(case sensitive)"
		    echo -e "ie. /home/USER/.wine/drive_c/Program Files/Roberts Space Industries/Star Citizen/"
		    while read -rp ": " game_path; do
			if [ ! -d "$game_path" ]; then
			    echo -e "That directory is invalid or does not exist. Please try again.\n"
			elif [ "$(basename "$game_path")" != "Star Citizen" ]; then
			    echo -e "You must enter the full path to the directory named 'Star Citizen'"
			else
			    break
			fi
		    done
		fi

		# Get the backup directory
		if [ -z "$backup_path" ]; then
		    echo -e "\nEnter the full path to a backup directory for your keybinds (case sensitive)"
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
	fi
	
        # Save the paths for later use
        echo "$wine_prefix" > "$conf_dir/$conf_subdir/$wine_conf"
        echo "$game_path" > "$conf_dir/$conf_subdir/$game_conf"
        echo "$backup_path" > "$conf_dir/$conf_subdir/$backup_conf"
    fi

    # Set some remaining directory paths
    user_dir="$game_path/$live_or_ptu/USER"
    mappings_dir="$user_dir/Controls/Mappings"
}

# Save exported keybinds, wipe the USER directory, and restore keybinds
sanitize() {    
    # Prompt user to back up the current keybinds in the game
    message 1 "Before proceeding, please be sure you have exported\nyour Star Citizen keybinds from within the game.\n\nTo do this, launch the game and go to:\nOptions->Keybindings->Control Profiles->Save Control Settings"

    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
	# User cancelled and wants to return to the main menu, or there was an error
	return 0
    fi

    # Sanity check
    if [ ! -d "$user_dir" ]; then
	message 2 "Directory not found. The helper is unable to proceed.\n\n$user_dir"
	return 0
    fi

    # Check for exported keybind files
    if [ ! -d "$mappings_dir" ] || [ -z "$(ls -A "$mappings_dir")" ]; then
	if message 3 "Warning: No exported keybindings found.\nContinuing will erase your existing keybinds!\n\nDo you want to continue anyway?"; then
	    exported=0
	else
	    # User said no
	    return 0
	fi
    else
	exported=1
    fi

    # Back up keybinds
    if [ "$exported" -eq 1 ]; then
	echo "Backing up all saved keybinds..."
	cp -r "$mappings_dir/." "$backup_path/keybinds/"
	echo -e "Done.\n"
    fi
    
    # Wipe the user directory
    echo "Wiping USER directory..."
    mv "$user_dir" "$backup_path/userbackup_$(date +"%Y%m%d-%H%M%S")"
    echo -e "Done.\n"

    # Restore custom keybinds
    if [ "$exported" -eq 1 ]; then
	echo "Restoring keybinds..."
	mkdir -p "$mappings_dir" && cp -r "$backup_path/keybinds/." "$mappings_dir/"
	echo -e "Done.\n"
	message 1 "To re-import your keybinds, select it in-game from the list:\nOptions->Keybindings->Control Profiles"
    fi

    message 1 "Your USER directory has been cleaned up!"
}

# Check if setting vm.max_map_count was successful
check_mapcount() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        message 2 "As far as this helper can detect, vm.max_map_count\nwas not successfully configured on your system.\n\nYou will most likely experience crashes."
    fi
}

# Check vm.max_map_count for the correct setting and let the user fix it if needed
set_mapcount() {
    # If vm.max_map_count is already set, no need to do anything
    if [ "$(cat /proc/sys/vm/max_map_count)" -ge 16777216 ]; then
    	message 1 "vm.max_map_count is already set to the optimal value.  You're all set!"
	return 0
    fi

    if grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then  
	if message 3 "It looks like you've already configured vm.max_map_count\nand saved the setting to persist across reboots.\nHowever, for some reason the persistence part did not work.\n\nFor now, would you like to enable the setting again until the next reboot?"; then
            pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
	fi
	check_mapcount
	return 0
    fi
    
    once="Change setting until next reboot"
    persist="Change setting and persist after reboot"
    manual="Show me the commands; I'll handle it myself"
    goback="Return to the main menu"
    
    newsysctl_msg="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl -p'"
    oldsysctl_msg="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"

    if message 3 "Running Star Citizen requires changing a system setting\nto give the game access to more than 8GB of memory.\n\nvm.max_map_count must be increased to at least 16777216\nto avoid crashes in areas with lots of geometry.\n\n\nAs far as this helper can detect, the setting\nhas not been changed on your system.\n\nWould you like to change the setting now?"; then
        if [ "$has_zen" -eq 1 ]; then
            # zenity menu
            options_mapcount=("--height=165" "TRUE" "$once" "FALSE" "$persist" "FALSE" "$manual")
            choice="$(message 4 "${options_mapcount[@]}")"
            case "$choice" in
                "$once")
        	    pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
		    check_mapcount
        	    ;;
                "$persist")
        	    if [ -d "/etc/sysctl.d" ]; then
                	pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.d/20-max_map_count.conf && sysctl -p'
        	    else
                        pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p'
        	    fi
		    check_mapcount
        	    ;;
                "$manual")
        	    if [ -d "/etc/sysctl.d" ]; then
                	message 1 "$newsysctl_msg"
        	    else
                	message 1 "$oldsysctl_msg"
        	    fi
        	    ;;
                *)
		    check_mapcount
		    return 0
        	    ;;
            esac
        else
            # text menu
	    clear
	    echo -e "\nThis helper can change vm.max_map_count for you.\nChoose from the following options:\n"
            options_mapcount=("$once" "$persist" "$manual" "$goback")
            PS3="Enter selection number: "

            select choice in "${options_mapcount[@]}"
            do
                case "$choice" in
                    "$once")
                	pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
			check_mapcount
                        break
                	;;
                    "$persist")
                	if [ -d "/etc/sysctl.d" ]; then
                            pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.d/20-max_map_count.conf && sysctl -p'
                	else
                            pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p'
                	fi
			check_mapcount
                        break
                	;;
                    "$manual")
                	if [ -d "/etc/sysctl.d" ]; then
                            message 1 "$newsysctl_msg"
                	else
                            message 1 "$oldsysctl_msg"
                	fi
                        break
                	;;
                    "$goback")
			check_mapcount
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

# Delete the shaders directory
rm_shaders() {    
    shaders_dir="$user_dir/Shaders"

    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
	# User cancelled and wants to return to the main menu, or there was an error
	return 0
    fi

    # Sanity check
    if [ ! -d "$shaders_dir" ]; then
	message 2 "Shaders directory not found. There is nothing to delete!\n\n$shaders_dir"
	return 0
    fi

    # Delete the shader directory
    echo "Deleting shaders..."
    rm -r "$shaders_dir"
    echo -e "Done.\n"

    message 1 "Your shaders have been deleted!"
}

# Delete DXVK cache
rm_vidcache() {    
    dxvk_cache="$game_path/$live_or_ptu/StarCitizen-dxvk.cache"

    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
	# User cancelled and wants to return to the main menu, or there was an error
	return 0
    fi

    # Sanity check
    if [ ! -f "$dxvk_cache" ]; then
	message 2 "Unable to find the DXVK cache file. There is nothing to delete!\n\n$dxvk_cache"
	return 0
    fi

    # Delete the cache file
    echo "Deleting DXVK cache..."
    rm "$dxvk_cache"
    echo -e "Done.\n"

    message 1 "Your DXVK cache has been deleted!"
}

# Toggle between targeting the LIVE and PTU game directories for all helper functions
set_version() {
    if [ "$live_or_ptu" == "LIVE" ]; then
	live_or_ptu="PTU"
	message 1 "The helper will now target your Star Citizen PTU installation."
    elif [ "$live_or_ptu" == "PTU" ]; then
	live_or_ptu="LIVE"
	message 1 "The helper will now target your Star Citizen LIVE installation."
    else
	echo -e "\nUnexpected game version provided.  Defaulting to the LIVE installation."
	live_or_ptu="LIVE"
    fi
}

# Display the main menu
main_menu() {
    # Set the menu options
    mapcount_msg="Check vm.max_map_count for optimal performance"
    sanitize_msg="Delete my USER folder and preserve my keybinds"
    shaders_msg="Delete my shaders only"
    vidcache_msg="Delete my DXVK cache"
    version_msg="Switch the helper between LIVE and PTU (default is LIVE)"
    quit_msg="Quit"

    # Use Zenity if it is available
    if [ "$has_zen" -eq 1 ]; then
	options_main=("TRUE" "$mapcount_msg" "FALSE" "$sanitize_msg" "FALSE" "$shaders_msg" "FALSE" "$vidcache_msg" "FALSE" "$version_msg")

	choice="$(message 5 "${options_main[@]}")"
	case "$choice" in
	    "$mapcount_msg")
		set_mapcount
		;;
	    "$sanitize_msg")
		sanitize
		;;
	    "$shaders_msg")
		rm_shaders
		;;
	    "$vidcache_msg")
		rm_vidcache
		;;
	    "$version_msg")
		set_version
		;;
	    *)
		exit 0
		;;
	esac
    else
	# Use a text menu if Zenity is not available
	clear
	echo -e "\nWelcome, fellow Penguin, to the Star Citizen Linux Users Group Helper!\n\nThis helper is designed to help optimize your system for Star Citizen\nYou may choose from the following options:\n"

	options_main=("$mapcount_msg" "$sanitize_msg" "$shaders_msg" "$vidcache_msg" "$version_msg" "$quit_msg")
	PS3="Enter selection number: "

	select choice in "${options_main[@]}"
	do
	    case "$choice" in
		"$mapcount_msg")
		    echo -e "\n"
		    set_mapcount
		    break
		    ;;
		"$sanitize_msg")
		    echo -e "\n"
		    sanitize
		    break
		    ;;
		"$shaders_msg")
		    echo -e "\n"
		    rm_shaders
		    break
		    ;;
		"$vidcache_msg")
		    echo -e "\n"
		    rm_vidcache
		    break
		    ;;
		"$version_msg")
		    echo -e "\n"
		    set_version
		    break
		    ;;
		"$quit_msg")
		    exit 0
		    ;;
		*)
		    echo -e "\nInvalid selection"
		    continue
		    ;;
	    esac
	done
    fi
}

############################################################################
# MAIN
############################################################################

# Check if Zenity is available
has_zen=0
if [ -x "$(command -v zenity)" ]; then
    has_zen=1
fi

# Default to LIVE
live_or_ptu="LIVE"

# Loop the main menu until the user selects quit
while true; do
    main_menu
done
