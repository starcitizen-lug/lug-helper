#!/bin/bash

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
# It also gives you a fast and easy way to wipe your Star Citizen
# USER folder as is recommended by CIG after major version updates.
# It will back up your exported keybinds, delete your USER folder,
# then restore your keybind file(s).
#
# To export your keybinds from within the game, go to
# Options->Keybindings->Control Profiles->Save Control Settings
#
# To import your keybinds from within the game, select them from the list:
# Options->Keybindings->Control Profiles
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

# The game's user subdirectory name
user_subdir_name="USER"
# The location within the USER directory to which the game exports keybinds
keybinds_export_path="Controls/Mappings"

dxvk_cache_file="StarCitizen.dxvk-cache"

# Lutris wine runners directory
if [ -z "$XDG_DATA_HOME" ]; then
    runner_dir="$HOME/.local/share/lutris/runners/wine"
else
    runner_dir="$XDG_DATA_HOME/lutris/runners/wine"
fi
# URLs for downloading Lutris runners
rawfox_url="https://api.github.com/repos/rawfoxDE/raw-wine/releases"
snatella_url="https://api.github.com/repos/snatella/wine-runner-sc/releases"

# Set a maximum number of runners
max_runners=20

############################################################################
############################################################################


# Display a message to the user.
# Expects the first argument to indicate the message type, followed by
# a string of arguments that will be passed to zenity or echoed to the user.
#
# To call this function, use the following format: message [type] "[string]"
# See the message types below for instructions on formatting the string.
message() {
    # Sanity check
    if [ "$#" -lt 2 ]; then
        echo -e "\nScript error: The message function expects two arguments. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    fi
    
    # Use zenity messages if available
    if [ "$has_zen" -eq 1 ]; then
        case "$1" in
            "info")
                # info message
                # call format: message info "text to display"
                margs=("--info" "--no-wrap" "--text=")
                ;;
            "warning")
                # warning message
                # call format: message warning "text to display"
                margs=("--warning" "--text=")
                ;;
            "question")
                # question
                # call format: if message question "question to ask?"; then...
                margs=("--question" "--text=")
                ;;
            *)
                echo -e "\nScript Error: Invalid message type passed to the message function. Aborting."
                read -n 1 -s -p "Press any key..."
                exit 0
                ;;
        esac

        # Display the message
        shift 1   # drop the first argument and shift the remaining up one
        zenity "${margs[@]}""$@" --width="400" --title="Star Citizen LUG Helper"
    else
        # Fall back to text-based messages when zenity is not available
        case "$1" in
            "info")
                # info message
                # call format: message info "text to display"
                clear
                echo -e "\n$2\n"
                read -n 1 -s -p "Press any key..."
                ;;
            "warning")
                # warning message
                # call format: message warning "text to display"
                clear
                echo -e "\n$2\n" 
                read -n 1 -s -p "Press any key..."
                return 0
                ;;
            "question")
                # question
                # call format: if message question "question to ask?"; then...
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
                echo -e "\nScript Error: Invalid message type passed to the message function. Aborting."
                read -n 1 -s -p "Press any key..."
                exit 0
                ;;
        esac
    fi
}

# Display a menu to the user.
# Uses Zenity for a gui menu with a fallback to plain old text.
#
# How to call this function:
#
# Requires two arrays to be set: "menu_options" and "menu_actions"
# two string variables: "menu_text_zenity" and "menu_text_terminal"
# and one integer variable: "menu_height".
#
# - The array "menu_options" should contain the strings of each option.
# - The array "menu_actions" should contain function names to be called.
# - The strings "menu_text_zenity" and "menu_text_terminal" should contain
#   the menu description formatted for zenity and the terminal, respectively.
#   This text will be displayed above the menu options.
#   Zenity supports Pango Markup for text formatting.
# - The integer "menu_height" specifies the height of the zenity menu.
# 
# The final element in each array is expected to be a quit option.
#
# IMPORTANT: The indices of the elements in "menu_actions"
# *MUST* correspond to the indeces in "menu_options".
# In other words, it is expected that menu_actions[1] is the correct action
# to be executed when menu_options[1] is selected, and so on for each element.
#
# See MAIN at the bottom of this script for an example of generating a menu.
menu() {
    # Sanity checks
    if [ "${#menu_options[@]}" -eq 0 ]; then
        echo -e "\nScript error: The array 'menu_options' was not set\nbefore calling the menu function. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    elif [ "${#menu_actions[@]}" -eq 0 ]; then
        echo -e "\nScript error: The array 'menu_actions' was not set\nbefore calling the menu function. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    elif [ -z "$menu_text_zenity" ]; then
        echo -e "\nScript error: The string 'menu_text_zenity' was not set\nbefore calling the menu function. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    elif [ -z "$menu_text_terminal" ]; then
        echo -e "\nScript error: The string 'menu_text_terminal' was not set\nbefore calling the menu function. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    elif [ -z "$menu_height" ]; then
        echo -e "\nScript error: The string 'menu_height' was not set\nbefore calling the menu function. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    fi
    
    # Use Zenity if it is available
    if [ "$has_zen" -eq 1 ]; then
        # Format the options array for Zenity by adding
        # TRUE or FALSE to indicate default selections
        # ie: "TRUE" "List item 1" "FALSE" "List item 2" "FALSE" "List item 3"
        for (( i=0; i<"${#menu_options[@]}"-1; i++ )); do
            if [ "$i" -eq 0 ]; then
                # Select the first radio button by default
                zen_options=("TRUE")
                zen_options+=("${menu_options[i]}")
            else
                zen_options+=("FALSE")
                zen_options+=("${menu_options[i]}")
            fi
        done

        # Display the zenity radio button menu
        choice="$(zenity --list --radiolist --width="400" --height="$menu_height" --text="$menu_text_zenity" --title="Star Citizen LUG Helper" --hide-header --column="" --column="Option" "${zen_options[@]}")"

        # Loop through the options array to match the chosen option
        matched="false"
        for (( i=0; i<"${#menu_options[@]}"; i++ )); do
            if [ "$choice" = "${menu_options[i]}" ]; then
                # Execute the corresponding action
                ${menu_actions[i]}
                matched="true"
                break
            fi
        done

        # If no match was found, the user clicked cancel
        if [ "$matched" = "false" ]; then
            # Execute the last option in the actions array
            "${menu_actions[${#menu_actions[@]}-1]}"
        fi
    else
        # Use a text menu if Zenity is not available
        clear
        echo -e "\n$menu_text_terminal\n"

        PS3="Enter selection number: "
        select choice in "${menu_options[@]}"
        do
            # Loop through the options array to match the chosen option
            matched="false"
            for (( i=0; i<"${#menu_options[@]}"; i++ )); do
                if [ "$choice" = "${menu_options[i]}" ]; then
                    # Execute the corresponding action
                    echo -e "\n"
                    ${menu_actions[i]}
                    matched="true"
                    break
                fi
            done

            # Check if we're done looping the menu
            if [ "$matched" = "true" ]; then
                # Match was found and actioned, so exit the menu
                break
            else
                # If no match was found, the user entered an invalid option
                echo -e "\nInvalid selection."
                continue
            fi
        done
    fi
}

# Get paths to the user's wine prefix, game directory, and a backup directory
getdirs() {
    # Sanity checks
    if [ ! -d "$conf_dir" ]; then
        message warning "Config directory not found. The helper is unable to proceed.\n\n$conf_dir"
        return 1
    fi
    if [ ! -d "$conf_dir/$conf_subdir" ]; then
        mkdir "$conf_dir/$conf_subdir"
    fi

    # Check if the config files already exist
    if [ -f "$conf_dir/$conf_subdir/$wine_conf" ]; then
        wine_prefix="$(cat "$conf_dir/$conf_subdir/$wine_conf")"
        if [ ! -d "$wine_prefix" ]; then
            echo -e "\nThe saved wine prefix does not exist, ignoring.\n"
            wine_prefix=""
        fi
    fi
    if [ -f "$conf_dir/$conf_subdir/$game_conf" ]; then
        game_path="$(cat "$conf_dir/$conf_subdir/$game_conf")"
        if [ ! -d "$game_path" ] || [ "$(basename "$game_path")" != "StarCitizen" ]; then
            echo -e "\nUnexpected game path found in config file, ignoring.\n"
            game_path=""
        fi
    fi
    if [ -f "$conf_dir/$conf_subdir/$backup_conf" ]; then
        backup_path="$(cat "$conf_dir/$conf_subdir/$backup_conf")"
        if [ ! -d "$backup_path" ]; then
            echo -e "\nThe saved backup path does not exist, ignoring.\n"
            backup_path=""
        fi
    fi

    # If we don't have the directory paths we need yet, ask the user to provide them
    if [ -z "$wine_prefix" ] || [ -z "$game_path" ] || [ -z "$backup_path" ]; then
        message info "You will now be asked to provide some directories needed by the helper.\n\nThey will be saved for later use in:\n$conf_dir/$conf_subdir/"
        if [ "$has_zen" -eq 1 ]; then
            # Get the wine prefix directory
            if [ -z "$wine_prefix" ]; then
                wine_prefix="$(zenity --file-selection --directory --title="Select your WINE prefix directory" --filename="$HOME/.wine")"
                if [ "$?" -eq -1 ]; then
                    message warning "An unexpected error has occurred. The helper is unable to proceed."
                    return 1
                elif [ -z "$wine_prefix" ]; then
                    # User clicked cancel
                    message warning "Operation cancelled.\nNo changes have been made to your game."
                    return 1
                fi
            fi

            # Get the game path
            if [ -z "$game_path" ]; then
                while game_path="$(zenity --file-selection --directory --title="Select your Star Citizen directory" --filename="$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen")"; do
                    if [ "$?" -eq -1 ]; then
                        message warning "An unexpected error has occurred. The helper is unable to proceed."
                        return 1
                    elif [ "$(basename "$game_path")" != "StarCitizen" ]; then
                        message warning "You must select the directory named 'StarCitizen'"
                    else
                        # All good or cancel
                        break
                    fi
                done
                
                if [ -z "$game_path" ]; then
                    # User clicked cancel
                    message warning "Operation cancelled.\nNo changes have been made to your game."
                    return 1
                fi
            fi

            # Get the backup directory
            if [ -z "$backup_path" ]; then
                while backup_path="$(zenity --file-selection --directory --title="Select a directory to back up your keybinds into" --filename="$HOME/")"; do
                    if [ "$?" -eq -1 ]; then
                        message warning "An unexpected error has occurred. The helper is unable to proceed."
                        return 1
                    elif [[ $backup_path == $game_path* ]]; then
                        message warning "Please select a backup location outside your Star Citizen directory.\nie. /home/USER/backups/"
                    else
                        # All good or cancel
                        break
                    fi
                done
                        
                if [ -z "$backup_path" ]; then
                    # User clicked cancel
                    message warning "Operation cancelled.\nNo changes have been made to your game."
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
                    echo -e "ie. /home/USER/.wine/drive_c/Program Files/Roberts Space Industries/StarCitizen/"
                    while read -rp ": " game_path; do
                        if [ ! -d "$game_path" ]; then
                            echo -e "That directory is invalid or does not exist. Please try again.\n"
                        elif [ "$(basename "$game_path")" != "StarCitizen" ]; then
                            echo -e "You must enter the full path to the directory named 'StarCitizen'\n"
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
                        elif [[ $backup_path == $game_path* ]]; then
                            echo -e "Please select a backup location outside your Star Citizen directory.\nie. /home/USER/backups/\n"
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
    user_dir="$game_path/$live_or_ptu/$user_subdir_name"
    keybinds_dir="$user_dir/$keybinds_export_path"
}

# Save exported keybinds, wipe the USER directory, and restore keybinds
sanitize() {    
    # Prompt user to back up the current keybinds in the game
    message info "Before proceeding, please be sure you have exported\nyour Star Citizen keybinds from within the game.\n\nTo do this, launch the game and go to:\nOptions->Keybindings->Control Profiles->Save Control Settings\n\nGo on; I'll wait."

    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu, or there was an error
        return 0
    fi

    # Sanity check
    if [ ! -d "$user_dir" ]; then
        message warning "USER directory not found. There is nothing to delete!\n\n$user_dir"
        return 0
    fi

    # Check for exported keybind files
    if [ ! -d "$keybinds_dir" ] || [ -z "$(ls -A "$keybinds_dir")" ]; then
        if message question "Warning: No exported keybindings found.\nContinuing will erase your existing keybinds!\n\nDo you want to continue anyway?"; then
            exported=0
        else
            # User said no
            return 0
        fi
    else
        exported=1
    fi

    if message question "This helper will delete the following directory:\n\n$user_dir\n\nDo you want to proceed?"; then
        # Back up keybinds
        if [ "$exported" -eq 1 ]; then
            echo "Backing up all saved keybinds..."
            cp -r "$keybinds_dir/." "$backup_path/keybinds/"
            echo -e "Done.\n"
        fi
        
        # Wipe the user directory
        echo "Wiping USER directory..."
        rm -r "$user_dir"
        echo -e "Done.\n"

        # Restore custom keybinds
        if [ "$exported" -eq 1 ]; then
            echo "Restoring keybinds..."
            mkdir -p "$keybinds_dir" && cp -r "$backup_path/keybinds/." "$keybinds_dir/"
            echo -e "Done.\n"
            message info "To re-import your keybinds, select it in-game from the list:\nOptions->Keybindings->Control Profiles"
        fi

        message info "Your Star Citizen USER directory has been cleaned up!"
    fi
}

# Check if setting vm.max_map_count was successful
mapcount_check() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        message warning "As far as this helper can detect, vm.max_map_count\nwas not successfully configured on your system.\n\nYou will most likely experience crashes."
    fi
}

# Sets vm.max_map_count for the current session only
mapcount_once() {
    pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
    mapcount_check
}

# Sets vm.max_map_count to persist between reboots
mapcount_persist() {
    if [ -d "/etc/sysctl.d" ]; then
        pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.d/20-max_map_count.conf && sysctl --system'
        message info "The necessary configuration has been appended to:\n/etc/sysctl.d/20-max_map_count.conf"
    else
        pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p'
        message info "The necessary configuration has been appended to:\n/etc/sysctl.conf"
    fi
    mapcount_check
}

# Displays instructions for the user to manually set vm.max_map_count
mapcount_manual() {
    if [ -d "/etc/sysctl.d" ]; then
        # Newer versions of sysctl
        message info "To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl --system'"
    else
        # Older versions of sysctl
        message info "To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"
    fi
}

# Check vm.max_map_count for the correct setting and let the user fix it
mapcount_set() {
    # If vm.max_map_count is already set, no need to do anything
    if [ "$(cat /proc/sys/vm/max_map_count)" -ge 16777216 ]; then
        message info "vm.max_map_count is already set to the optimal value.\nYou're all set!"
        return 0
    fi

    # Otherwise, check to see if it was supposed to be set by sysctl
    if grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then  
        if message question "It looks like you've already configured vm.max_map_count\nand saved the setting to persist across reboots.\nHowever, for some reason the persistence part did not work.\n\nFor now, would you like to enable the setting again until the next reboot?"; then
            pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
        fi
        mapcount_check
        return 0
    fi
    
    # Configure the menu
    menu_text_zenity="<b>This helper can change vm.max_map_count for you</b>\n\nChoose from the following options:"
    menu_text_terminal="This helper can change vm.max_map_count for you\n\nChoose from the following options:"
    menu_height="200"
    
    # Configure the menu options
    once="Change setting until next reboot"
    persist="Change setting and persist after reboot"
    manual="Show me the commands; I'll handle it myself"
    goback="Return to the main menu"
    
    # Set the options to be displayed in the menu
    menu_options=("$once" "$persist" "$manual" "$goback")
    # Set the corresponding functions to be called for each of the options
    menu_actions=("mapcount_once" "mapcount_persist" "mapcount_manual" "mapcount_check")
    
    # Display an informational message to the user
    message info "Running Star Citizen requires changing a system setting\nto give the game access to more than 8GB of memory.\n\nvm.max_map_count must be increased to at least 16777216\nto avoid crashes in areas with lots of geometry.\n\n\nAs far as this helper can detect, the setting\nhas not been changed on your system.\n\nYou will now be given the option to change it."
    
    # Call the menu function.  It will use the options as configured above
    menu
}

# Check if setting the open file descriptors limit was successful
filelimit_check() {
    if [ "$(ulimit -Hn)" -lt 524288 ]; then
        message warning "As far as this helper can detect, the open files limit\nwas not successfully configured on your system.\nYou may experience crashes.\n\nWe recommend manually configuring this limit to at least 524288."
    fi
}

# Check the open file descriptors limit and let the user fix it if needed
filelimit_set() {
    filelimit="$(ulimit -Hn)"

    # If the file limit is already set, no need to do anything
    if [ "$filelimit" -ge 524288 ]; then
        message info "Your open files limit is already set to the optimal value.\nYou're all set!"
        return 0
    fi

    # Adjust the limit
    if message question "We recommend setting the hard open\nfile descriptors limit to at least 524288.\n\nThe current value on your system appears to be $filelimit.\n\nWould you like this helper to change it for you?"; then
        if [ -f "/etc/systemd/system.conf" ]; then
            # Using systemd
            # Append to the file
            pkexec sh -c 'echo "DefaultLimitNOFILE=524288" >> /etc/systemd/system.conf && systemctl daemon-reexec'
            message info "The necessary configuration has been appended to:\n/etc/systemd/system.conf"
        elif [ -f "/etc/security/limits.conf" ]; then
            # Using limits.conf
            # Insert before the last line in the file
            pkexec sh -c 'sed -i "\$i* hard nofile 524288" /etc/security/limits.conf'
            message info "The necessary configuration has been appended to:\n/etc/security/limits.conf"
        else
            # Don't know what method to use
            message warning "This helper is unable to detect the correct method of setting\nthe open file descriptors limit on your system.\n\nWe recommend manually configuring this limit to at least 524288."
            return 0
        fi
    fi

    # Verify that setting the limit was successful
    filelimit_check
}

# Delete the shaders directory
rm_shaders() {    
    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu, or error
        return 0
    fi

    shaders_dir="$user_dir/Shaders"

    # Sanity check
    if [ ! -d "$shaders_dir" ]; then
        message warning "Shaders directory not found. There is nothing to delete!\n\n$shaders_dir"
        return 0
    fi

    # Delete the shader directory
    if message question "This helper will delete the following directory:\n\n$shaders_dir\n\nDo you want to proceed?"; then
        echo "Deleting shaders..."
        rm -r "$shaders_dir"
        echo -e "Done.\n"
        message info "Your shaders have been deleted!"
    fi
}

# Delete DXVK cache
rm_vidcache() {    
    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu, or there was an error
        return 0
    fi
    
    dxvk_cache="$game_path/$live_or_ptu/$dxvk_cache_file"
    
    # Sanity check
    if [ ! -f "$dxvk_cache" ]; then
        message warning "Unable to find the DXVK cache file. There is nothing to delete!\n\n$dxvk_cache"
        return 0
    fi

    # Delete the cache file
    if message question "This helper will delete the following file:\n\n$dxvk_cache\n\nDo you want to proceed?"; then
        echo "Deleting DXVK cache..."
        rm "$dxvk_cache"
        echo -e "Done.\n"
        message info "Your DXVK cache has been deleted!"
    fi
}

# Toggle between targeting the LIVE and PTU game directories for all helper functions
set_version() {
    if [ "$live_or_ptu" = "LIVE" ]; then
        live_or_ptu="PTU"
        message info "The helper will now target your Star Citizen PTU installation."
    elif [ "$live_or_ptu" = "PTU" ]; then
        live_or_ptu="LIVE"
        message info "The helper will now target your Star Citizen LIVE installation."
    else
        echo -e "\nUnexpected game version provided.  Defaulting to the LIVE installation."
        live_or_ptu="LIVE"
    fi
}

quit() {
    exit 0
}

mainmenu() {
    #message info "Aborting - going back to Mainmenu"
    echo "going back to menu"
}

# Restart lutris
lutris_restart() {
    if message question "Lutris must be restarted to refresh the downloaded runners.\nWould you like this helper to restart it for you?"; then
        if [ "$(pgrep lutris)" ]; then
            echo -e "\nRestarting Lutris...\n"
            pkill -SIGTERM lutris && nohup lutris </dev/null &>/dev/null &
        else
            message info "Lutris does not appear to be running."
        fi
    fi
}

delete_runner() {
    remove_option="$1"
    if message question "Are you sure you want to delete the following runner?\n\n${installed_runners[$remove_option]}"; then
        rm -r "${installed_runners[$remove_option]}"
        echo -e "\nDeleted ${installed_runners[$remove_option]}\n"
    fi

    # Restart Lutris
    lutris_restart
}
 
choose_runner_to_delete() {
    # Configure the menu
    menu_text_zenity="Select the Lutris runner you want to delete:"
    menu_text_terminal="Select the Lutris runner you want to delete:"
    menu_height="300"
    goback="Return to the runner management menu"
    unset installed_runners
    unset menu_options
    unset menu_actions
     
    # Create an array containing all directories in the runner_dir
    for runners_list in "$runner_dir"/*; do
        if [ -d "$runners_list" ]; then
            installed_runners+=("$runners_list")
        fi
    done
    
    # Create menu options for the installed runners
    for (( i=0; i<"${#installed_runners[@]}"; i++ )); do
        menu_options+=("$(basename "${installed_runners[i]}")")
        menu_actions+=("delete_runner $i")
    done
    
    # Complete the menu by adding the option to go back to the previous menu
    menu_options+=("$goback")
    menu_actions+=("manage_runners")
    
    # Call the menu function.  It will use the options as configured above
    menu
}

install_runner() {
    # This function expects an index number for the array runner_versions to be passed in as an argument
    if [ -z "$1" ]; then
        echo -e "\nScript error:  The install runner function expects an argument. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    fi
    
    # Use menu selection from last menu to select version from array 
    runner_name="${runner_versions[$1]}"
    runner_url="$(curl -s "$latest_url" | grep "browser_download_url.*$runner_name" | cut -d \" -f4)"
    
    # Sanity check
    if [ -z "$runner_url" ]; then
        message warning "Could not find the requested runner.  The Github API may be down or rate limited."
        return 1
    fi

    message info "The selected runner will now be downloaded.\nThis might take a moment."
    
    # Download and extract the runner
    if [ "$latest_url" == "$snatella_url" ]; then
        # Runners without a subdirectory in the archive
        echo -e "\nDownloading $runner_url\ninto $runner_dir/$runner_name\n"
        mkdir -p "$runner_dir/$runner_name" && curl -L "$runner_url" | tar -xzf - -C "$runner_dir/$runner_name"
    else
        # Runners with a subdirectory in the archive
        echo -e "\nDownloading $runner_url\ninto $runner_dir\n"
        mkdir -p "$runner_dir" && curl -L "$runner_url" | tar -xzf - -C "$runner_dir"
    fi

    # Restart Lutris
    lutris_restart
}
    
choose_runner_version() {
    # This function expects the name of the runner contributor to be passed in as an argument
    if [ -z "$1" ]; then
        echo -e "\nScript error:  The choose runner function expects an argument. Aborting."
        read -n 1 -s -p "Press any key..."
        exit 0
    fi
    
    # set download urls
    case "$1" in
        "snatella")
            latest_url="$snatella_url"
            runner_versions=($(curl -s "$latest_url" | grep "browser_download_url" | awk '{print $2}' | xargs basename -as .tgz))
            ;;
        "rawfox")
            latest_url="$rawfox_url"
            runner_versions=($(curl -s "$latest_url" | grep "browser_download_url" | awk '{print $2}' | xargs basename -as .tar.gz))
            ;;
        *)
            echo -e "\nScript Error: Invalid parameter passed to the runner version function.  Aborting."
            read -n 1 -s -p "Press any key..."
            exit 0
            ;;
    esac

    # Sanity check
    if [ "${#runner_versions[@]}" -eq 0 ]; then
        message warning "No runner versions were found.  The Github API may be down or rate limited."
        return 1
    fi   

    # Configure the menu
    menu_text_zenity="Select the Lutris runner you want  to install:"
    menu_text_terminal="Select the Lutris runner you want to install:"
    menu_height="500"
    goback="Return to the runner management menu"
    unset menu_options
    unset menu_actions

    # Allow up to max_runners to be displayed in the list
    if [ "${#runner_versions[@]}" -gt "$max_runners" ]; then
        runner_count="$max_runners"
    else
        runner_count="${#runner_versions[@]}"
    fi
    
    # Iterate through the versions, check if they are installed, and add them to the menu options
    for (( i=0; i<"$runner_count"; i++ )); do
        if [ -d "$runner_dir/${runner_versions[i]}" ]; then
            menu_options+=("${runner_versions[i]}    [installed]")
        else
            menu_options+=("${runner_versions[i]}")
        fi
        menu_actions+=("install_runner $i")
    done

    # Complete the menu by adding the option to go back to the previous menu
    menu_options+=("$goback")
    menu_actions+=("manage_runners")
    
    # Call the menu function.  It will use the options as configured above
    menu
}

    
manage_runners() {
    # Check if Lutris is installed
    if [ ! -x "$(command -v lutris)" ]; then
        message info "Lutris does not appear to be installed."
        return 1
    fi
    
    # Configure the menu
    menu_text_zenity="<b>This helper can manage your Lutris runners</b>\n\nChoose from the following options:"
    menu_text_terminal="This helper can manage your Lutris runners<\n\nChoose from the following options:"
    menu_height="200"

    # Configure the menu options
    rawfox="Install a runner from RawFox"
    snatella="Install a runner from Molotov/Snatella"
    delete="Delete an installed runner"
    back="Return to the main menu"
    # Set the options to be displayed in the menu
    menu_options=("$rawfox" "$snatella" "$delete" "$back")
    # Set the corresponding functions to be called for each of the options
    menu_actions=("choose_runner_version rawfox" "choose_runner_version snatella" "choose_runner_to_delete" "mainmenu")

    # Call the menu function.  It will use the options as configured above
    menu
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
    # Configure the menu
    menu_text_zenity="<b><big>Welcome, fellow Penguin, to the Star Citizen LUG Helper!</big>\n\nThis helper is designed to help optimize your system for Star Citizen</b>\n\nYou may choose from the following options:"
    menu_text_terminal="Welcome, fellow Penguin, to the Star Citizen Linux Users Group Helper!\n\nThis helper is designed to help optimize your system for Star Citizen\nYou may choose from the following options:"
    menu_height="340"

    # Configure the menu options
    runners_msg="Manage Lutris Runners"
    sanitize_msg="Delete my Star Citizen USER folder and preserve my keybinds"
    mapcount_msg="Check vm.max_map_count for optimal performance"
    filelimit_msg="Check my open file descriptors limit"
    shaders_msg="Delete my shaders only"
    vidcache_msg="Delete my DXVK cache"
    version_msg="Switch the helper between LIVE and PTU (default is LIVE)"
    quit_msg="Quit"
    
    # Set the options to be displayed in the menu
    menu_options=("$runners_msg" "$sanitize_msg" "$mapcount_msg" "$filelimit_msg" "$shaders_msg" "$vidcache_msg" "$version_msg" "$quit_msg")
    # Set the corresponding functions to be called for each of the options
    menu_actions=("manage_runners" "sanitize" "mapcount_set" "filelimit_set" "rm_shaders" "rm_vidcache" "set_version" "quit")
    
    # Call the menu function.  It will use the options as configured above
    menu
done
