#!/usr/bin/env bash

############################################################################
# Star Citizen's Linux Users Group Helper Script
############################################################################
#
# Greetings, Space Penguin!
#
#
# This script is designed to help you manage and optimize
# Star Citizen on Linux.
#
# Features:
#
# - Check your system for optimal settings and
#   change them as needed to prevent crashes.
#
# - Easily install and remove Lutris wine Runners.
#
# - Qickly wipe your Star Citizen USER folder as is recommended
#   by CIG after major version updates.
#   It will back up your exported keybinds, delete your USER folder,
#   then restore your keybind file(s).
#
# - Get a random participating LUG member's Star Citizen referral code.
#
# - Supports both the LIVE and PTU environments.
#
# - Zenity menus are used for a GUI experience with a fallback to
#   terminal-based menus where Zenity is unavailable.
#
#
# To export your keybinds from within the game, go to
# Options->Keybindings->Control Profiles->Save Control Settings
#
# To import your keybinds from within the game, select them from the list:
# Options->Keybindings->Control Profiles
#
#
# made with <3
# Author: https://github.com/the-sane
# Contributor: https://github.com/Termuellinator
# Contributor: https://github.com/pstn
# v1.4
############################################################################

# Check for dependencies
if [ ! -x "$(command -v curl)" ]; then
# Print to stderr and also try warning the user through notify-send
    printf "lug-helper.sh: The required package 'curl' was not found on this system.\n" 1>&2
    notify-send "lug-helper" "The required package 'curl' was not found on this system.\n" --icon=dialog-warning
    exit 1
fi
if [ ! -x "$(command -v mktemp)" ] || [ ! -x "$(command -v basename)" ]; then
    # Print to stderr and also try warning the user through notify-send
    printf "lug-helper.sh: One or more required packages were not found on this system.\nPlease check that the following packages are installed:\n- mktemp (part of gnu coreutils)\n- basename (part of gnu coreutils)\n" 1>&2
    notify-send "lug-helper" "One or more required packages were not found on this system.\nPlease check that the following packages are installed:\n- mktemp (part of gnu coreutils)\n- basename (part of gnu coreutils)\n" --icon=dialog-warning
    exit 1
fi

wine_conf="winedir.conf"
game_conf="gamedir.conf"
backup_conf="backupdir.conf"

# Use XDG base directories if defined
if [ -z "$XDG_CONFIG_HOME" ]; then
    conf_dir="$HOME/.config"
else
    conf_dir="$XDG_CONFIG_HOME"
fi
if [ -z "$XDG_DATA_HOME" ]; then
    data_dir="$HOME/.local/share"
else
    data_dir="$XDG_DATA_HOME"
fi

# .config subdirectory
conf_subdir="starcitizen-lug"

# Temporary directory
tmp_dir="$(mktemp -d --suffix=".lughelper")"
trap 'rm -r "$tmp_dir"' EXIT

# The game's user subdirectory name
user_subdir_name="USER"
# The location within the USER directory to which the game exports keybinds
keybinds_export_path="Controls/Mappings"

dxvk_cache_file="StarCitizen.dxvk-cache"

# Lutris wine runners directory
runners_dir="$data_dir/lutris/runners/wine"
# URLs for downloading Lutris runners
# Elements in this array must be added in quoted pairs of: "description" "url"
# The first string in the pair is expected to contain the runner description
# The second is expected to contain the github api releases url
# ie. "RawFox" "https://api.github.com/repos/rawfoxDE/raw-wine/releases"
runner_sources=(
    "RawFox" "https://api.github.com/repos/rawfoxDE/raw-wine/releases"
    "Molotov/Snatella" "https://api.github.com/repos/snatella/wine-runner-sc/releases"
)
# Set a maximum number of runner versions to display from each url
max_runners=20

# Pixels to add for each Zenity menu option
# used to dynamically determine the height of menus
menu_option_height="25"

############################################################################
############################################################################


# Echo a formatted debug message to the terminal and optionally exit
# Accepts either "continue" or "exit" as the first argument
# followed by the string to be echoed
debug_echo() {
    # This function expects two string arguments
    if [ "$#" -lt 2 ]; then
        printf "\nScript error:  The debug_echo function expects two arguments. Aborting.\n"
        read -n 1 -s -p "Press any key..."
        exit 0
    fi

    # Echo the provided string and, optionally, exit the script
    case "$1" in
        "continue")
            printf "\n$2\n"
            ;;
        "exit")
            # Write an error to stderr and exit
            printf "lug-helper.sh: $2\n" 1>&2
            read -n 1 -s -p "Press any key..."
            exit 1
            ;;
        *)
            printf "lug-helper.sh: Unknown argument provided to debug_echo function. Aborting.\n" 1>&2
            read -n 1 -s -p "Press any key..."
            exit 0
            ;;
    esac
}

# Display a message to the user.
# Expects the first argument to indicate the message type, followed by
# a string of arguments that will be passed to zenity or echoed to the user.
#
# To call this function, use the following format: message [type] "[string]"
# See the message types below for instructions on formatting the string.
message() {
    # Sanity check
    if [ "$#" -lt 2 ]; then
        debug_echo exit "Script error: The message function expects two arguments. Aborting."
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
                debug_echo exit "Script Error: Invalid message type passed to the message function. Aborting."
                ;;
        esac

        # Display the message
        shift 1   # drop the first argument and shift the remaining up one
        zenity "${margs[@]}""$@" --width="400" --title="Star Citizen LUG Helper" 2>/dev/null
    else
        # Fall back to text-based messages when zenity is not available
        case "$1" in
            "info")
                # info message
                # call format: message info "text to display"
                clear
                printf "\n$2\n\n"
                read -n 1 -s -p "Press any key..."
                ;;
            "warning")
                # warning message
                # call format: message warning "text to display"
                clear
                printf "\n$2\n\n"
                read -n 1 -s -p "Press any key..."
                return 0
                ;;
            "question")
                # question
                # call format: if message question "question to ask?"; then...
                clear
                printf "$2\n"
                while read -p "[y/n]: " yn; do
                    case "$yn" in
                        [Yy]*)
                            return 0
                            ;;
                        [Nn]*)
                            return 1
                            ;;
                        *)
                            printf "Please type 'y' or 'n'\n"
                            ;;
                    esac
                done
                ;;
            *)
                debug_echo exit "Script Error: Invalid message type passed to the message function. Aborting."
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
        debug_echo exit "Script error: The array 'menu_options' was not set\nbefore calling the menu function. Aborting."
    elif [ "${#menu_actions[@]}" -eq 0 ]; then
        debug_echo exit "Script error: The array 'menu_actions' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$menu_text_zenity" ]; then
        debug_echo exit "Script error: The string 'menu_text_zenity' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$menu_text_terminal" ]; then
        debug_echo exit "Script error: The string 'menu_text_terminal' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$menu_height" ]; then
        debug_echo exit "Script error: The string 'menu_height' was not set\nbefore calling the menu function. Aborting."
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
        choice="$(zenity --list --radiolist --width="400" --height="$menu_height" --text="$menu_text_zenity" --title="Star Citizen LUG Helper" --hide-header --column="" --column="Option" "${zen_options[@]}" 2>/dev/null)"

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
        printf "\n$menu_text_terminal\n\n"

        PS3="Enter selection number: "
        select choice in "${menu_options[@]}"
        do
            # Loop through the options array to match the chosen option
            matched="false"
            for (( i=0; i<"${#menu_options[@]}"; i++ )); do
                if [ "$choice" = "${menu_options[i]}" ]; then
                    # Execute the corresponding action
                    printf "\n\n"
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
                printf "\nInvalid selection.\n"
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
        mkdir -p "$conf_dir/$conf_subdir"
    fi

    # Check if the config files already exist
    if [ -f "$conf_dir/$conf_subdir/$wine_conf" ]; then
        wine_prefix="$(cat "$conf_dir/$conf_subdir/$wine_conf")"
        if [ ! -d "$wine_prefix" ]; then
            debug_echo continue "The saved wine prefix does not exist, ignoring."
            wine_prefix=""
        fi
    fi
    if [ -f "$conf_dir/$conf_subdir/$game_conf" ]; then
        game_path="$(cat "$conf_dir/$conf_subdir/$game_conf")"
        if [ ! -d "$game_path" ] || [ "$(basename "$game_path")" != "StarCitizen" ]; then
            debug_echo continue "Unexpected game path found in config file, ignoring."
            game_path=""
        fi
    fi

    # If we don't have the directory paths we need yet,
    # ask the user to provide them
    if [ -z "$wine_prefix" ] || [ -z "$game_path" ]; then
        message info "At the next screen, please select your Star Citizen WINE prefix.\n\nIt will be saved for future use in:\n$conf_dir/$conf_subdir/"
        if [ "$has_zen" -eq 1 ]; then
            # Using Zenity file selection menus
            # Get the wine prefix directory
            if [ -z "$wine_prefix" ]; then
                wine_prefix="$(zenity --file-selection --directory --title="Select your Star Citizen WINE prefix directory" --filename="$HOME/Games/star-citizen" 2>/dev/null)"
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
                if [ -d "$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen" ] && 
                       message question "Is this your Star Citizen game directory?\n\n$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen"; then
                    game_path="$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen"
                else
                    while game_path="$(zenity --file-selection --directory --title="Select your Star Citizen directory" --filename="$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen" 2>/dev/null)"; do
                        if [ "$?" -eq -1 ]; then
                            message warning "An unexpected error has occurred. The helper is unable to proceed."
                            return 1
                        elif [ "$(basename "$game_path")" != "StarCitizen" ]; then
                            message warning "You must select the Star Citizen base game directory.\n\nFor Example:  prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen"
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
            fi
        else
            # No Zenity, use terminal-based menus
            clear
            # Get the wine prefix directory
            if [ -z "$wine_prefix" ]; then
                printf "Enter the full path to your Star Citizen WINE prefix directory (case sensitive)\n"
                printf "ie. /home/USER/Games/star-citizen\n"
                while read -rp ": " wine_prefix; do
                    if [ ! -d "$wine_prefix" ]; then
                        printf "That directory is invalid or does not exist. Please try again.\n\n"
                    else
                        break
                    fi
                done
            fi

            # Get the game path
            if [ -z "$game_path" ]; then
                if [ -d "$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen" ] && 
                       message question "Is this your Star Citizen game directory?\n\n$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen"; then
                    game_path="$wine_prefix/drive_c/Program Files/Roberts Space Industries/StarCitizen"
                else
                    printf "\nEnter the full path to your Star Citizen installation directory (case sensitive)\n"
                    printf "ie. /home/USER/Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen\n"
                    while read -rp ": " game_path; do
                        if [ ! -d "$game_path" ]; then
                            printf "That directory is invalid or does not exist. Please try again.\n\n"
                        elif [ "$(basename "$game_path")" != "StarCitizen" ]; then
                            printf "You must enter the full path to the directory named 'StarCitizen'\n\n"
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
    fi

    # Set some remaining directory paths
    user_dir="$game_path/$live_or_ptu/$user_subdir_name"
    keybinds_dir="$user_dir/$keybinds_export_path"
    backup_path="$conf_dir/$conf_subdir"
}

# Save exported keybinds, wipe the USER directory, and restore keybinds
sanitize() {
    # Prompt user to back up the current keybinds in the game
    message info "Before proceeding, please be sure you have exported\nyour Star Citizen keybinds from within the game.\n\nTo do this, launch the game and go to:\nOptions->Keybindings->Control Profiles->Save Control Settings\n\nGo on; I'll wait."

    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu
        # or there was an error
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
            debug_echo continue "Backing up keybinds to $backup_path/keybinds..."
            mkdir -p "$backup_path/keybinds" && cp -r "$keybinds_dir/." "$backup_path/keybinds/"
        fi
        
        # Wipe the user directory
        debug_echo continue "Wiping USER directory..."
        rm -r "$user_dir"

        # Restore custom keybinds
        if [ "$exported" -eq 1 ]; then
            debug_echo continue "Restoring keybinds..."
            mkdir -p "$keybinds_dir" && cp -r "$backup_path/keybinds/." "$keybinds_dir/"
            message info "To re-import your keybinds, select it in-game from the list:\nOptions->Keybindings->Control Profiles"
        fi

        message info "Your Star Citizen USER directory has been cleaned up!"
    fi
}

#------------------------- begin mapcount functions --------------------------#

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
    menu_text_height="100"
    
    # Configure the menu options
    once="Change setting until next reboot"
    persist="Change setting and persist after reboot"
    manual="Show me the commands; I'll handle it myself"
    goback="Return to the main menu"
    
    # Set the options to be displayed in the menu
    menu_options=("$once" "$persist" "$manual" "$goback")
    # Set the corresponding functions to be called for each of the options
    menu_actions=("mapcount_once" "mapcount_persist" "mapcount_manual" "mapcount_check")

    # Calculate the total height the menu should be
    menu_height="$(("$menu_option_height" * "${#menu_options[@]}" + "$menu_text_height"))"
    
    # Display an informational message to the user
    message info "Running Star Citizen requires changing a system setting\nto give the game access to more than 8GB of memory.\n\nvm.max_map_count must be increased to at least 16777216\nto avoid crashes in areas with lots of geometry.\n\n\nAs far as this helper can detect, the setting\nhas not been changed on your system.\n\nYou will now be given the option to change it."
    
    # Call the menu function.  It will use the options as configured above
    menu
}

#-------------------------- end mapcount functions ---------------------------#

#------------------------ begin filelimit functions --------------------------#

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

#------------------------- end filelimit functions ---------------------------#


# Delete the shaders directory
rm_shaders() {
    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu, or error
        return 0
    fi

    shaders_dir="$user_dir/shaders"

    # Sanity check
    if [ ! -d "$shaders_dir" ]; then
        message warning "Shaders directory not found. There is nothing to delete!\n\n$shaders_dir"
        return 0
    fi

    # Delete the shader directory
    if message question "This helper will delete the following directory:\n\n$shaders_dir\n\nDo you want to proceed?"; then
        debug_echo continue "Deleting $shaders_dir..."
        rm -r "$shaders_dir"
        message info "Your shaders have been deleted!"
    fi
}

# Delete DXVK cache
rm_vidcache() {
    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu
        # or there was an error
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
        debug_echo continue "Deleting $dxvk_cache..."
        rm "$dxvk_cache"
        message info "Your DXVK cache has been deleted!"
    fi
}

#------------------------- begin runner functions ----------------------------#

# Restart lutris
lutris_restart() {
    if [ "$lutris_needs_restart" = "true" ] && [ "$(pgrep lutris)" ]; then
        if message question "Lutris must be restarted to detect runner changes.\nWould you like this helper to restart it for you?"; then
            debug_echo continue "Restarting Lutris..."
            pkill -SIGTERM lutris && nohup lutris </dev/null &>/dev/null &
        fi
    fi
    lutris_needs_restart="false"
}

# Delete the selected runner
runner_delete() {
    # This function expects an index number for the array
    # installed_runners to be passed in as an argument
    if [ -z "$1" ]; then
        debug_echo exit "Script error:  The runner_delete function expects an argument. Aborting."
    fi
    
    runner_to_delete="$1"
    if message question "Are you sure you want to delete the following runner?\n\n${installed_runners[$runner_to_delete]}"; then
        rm -r "${installed_runners[$runner_to_delete]}"
        debug_echo continue "Deleted ${installed_runners[$runner_to_delete]}"
        lutris_needs_restart="true"
    fi
}

# List installed runners for deletion
runner_select_delete() {
    # Configure the menu
    menu_text_zenity="Select the Lutris runner you want to remove:"
    menu_text_terminal="Select the Lutris runner you want to remove:"
    menu_text_height="65"
    goback="Return to the runner management menu"
    unset installed_runners
    unset menu_options
    unset menu_actions
     
    # Create an array containing all directories in the runners_dir
    for runners_list in "$runners_dir"/*; do
        if [ -d "$runners_list" ]; then
            installed_runners+=("$runners_list")
        fi
    done
    
    # Create menu options for the installed runners
    for (( i=0; i<"${#installed_runners[@]}"; i++ )); do
        menu_options+=("$(basename "${installed_runners[i]}")")
        menu_actions+=("runner_delete $i")
    done
    
    # Complete the menu by adding the option to go back to the previous menu
    menu_options+=("$goback")
    menu_actions+=(":") # no-op

    # Calculate the total height the menu should be
    menu_height="$(("$menu_option_height" * "${#menu_options[@]}" + "$menu_text_height"))"
    if [ "$menu_height" -gt "400" ]; then
        menu_height="400"
    fi
    
    # Call the menu function.  It will use the options as configured above
    menu
}

# Download and install the selected runner
# Note: The variables runner_versions, contributor_url, and runner_url_type
# are expected to be set before calling this function
runner_install() {
    # This function expects an index number for the array
    # runner_versions to be passed in as an argument
    if [ -z "$1" ]; then
        debug_echo exit "Script error:  The runner_install function expects a numerical argument. Aborting."
    fi

    # Get the runner filename including file extension
    runner_file="${runner_versions[$1]}"

    # Get the selected runner name minus the file extension
    # To add new file extensions, handle them here and in
    # the runner_select_install function below
    case "$runner_file" in
        *.tar.gz)
            runner_name="$(basename "$runner_file" .tar.gz)"
            ;;
        *.tgz)
            runner_name="$(basename "$runner_file" .tgz)"
            ;;
        *)
            debug_echo exit "Unknown archive filetype in runner_install function. Aborting."
            ;;
    esac

    # Get the selected runner url
    # To add new sources, handle them here and in the
    # runner_select_install function below
    if [ "$runner_url_type" = "github" ]; then
        runner_dl_url="$(curl -s "$contributor_url" | grep "browser_download_url.*$runner_file" | cut -d \" -f4)"
    else
        debug_echo exit "Script error:  Unknown api/url format in runner_sources array. Aborting."
    fi

    # Sanity check
    if [ -z "$runner_dl_url" ]; then
        message warning "Could not find the requested runner.  The source API may be down or rate limited."
        return 1
    fi

    # Download the runner to the tmp directory
    debug_echo continue "Downloading $runner_dl_url into $tmp_dir/$runner_file..."
    if [ "$has_zen" -eq 1 ]; then
        # Format the curl progress bar for zenity
        mkfifo "$tmp_dir/lugpipe"
        cd "$tmp_dir" && curl -#LO "$runner_dl_url" > "$tmp_dir/lugpipe" 2>&1 & curlpid="$!"
        stdbuf -oL tr '\r' '\n' < "$tmp_dir/lugpipe" | \
        grep --line-buffered -ve "100" | grep --line-buffered -o "[0-9]*\.[0-9]" | \
        (
            trap 'kill "$curlpid"' ERR
            zenity --progress --auto-close --title="Star Citizen LUG Helper" --text="Downloading Runner.  This might take a moment.\n" 2>/dev/null
        )

        if [ "$?" -eq 1 ]; then
            # User clicked cancel
            debug_echo continue "Download aborted. Removing $tmp_dir/$runner_file..."
            rm "$tmp_dir/$runner_file"
            rm "$tmp_dir/lugpipe"
            return 1
        fi
        rm "$tmp_dir/lugpipe"
    else
        # Standard curl progress bar
        (cd "$tmp_dir" && curl -LO "$runner_dl_url")
    fi

    # Sanity check
    if [ ! -f "$tmp_dir/$runner_file" ]; then
        debug_echo exit "Script error:  The requested runner file was not downloaded. Aborting"
    fi  
    
    # Get the path of the first item listed in the archive
    # This should either be a subdirectory or the path ./
    # depending on how the archive was created
    first_filepath="$(stdbuf -oL tar -tzf "$tmp_dir/$runner_file" | head -n 1)"
    
    # Extract the runner
    case "$first_filepath" in
        # If the files in the archive begin with ./ there is no subdirectory
        ./*)
            debug_echo continue "Installing runner into $runners_dir/$runner_name..."
            if [ "$has_zen" -eq 1 ]; then
                # Use Zenity progress bar
                mkdir -p "$runners_dir/$runner_name" && tar -xzf "$tmp_dir/$runner_file" -C "$runners_dir/$runner_name" | \
                zenity --progress --pulsate --no-cancel --auto-close --title="Star Citizen LUG Helper" --text="Installing runner...\n" 2>/dev/null
            else
                mkdir -p "$runners_dir/$runner_name" && tar -xzf "$tmp_dir/$runner_file" -C "$runners_dir/$runner_name"
            fi
            lutris_needs_restart="true"
            ;;
        *)
            # Runners with a subdirectory in the archive
            debug_echo continue "Installing runner into $runners_dir..."
            if [ "$has_zen" -eq 1 ]; then
                # Use Zenity progress bar
                mkdir -p "$runners_dir" && tar -xzf "$tmp_dir/$runner_file" -C "$runners_dir" | \
                zenity --progress --pulsate --no-cancel --auto-close --title="Star Citizen LUG Helper" --text="Installing runner...\n" 2>/dev/null
            else
                mkdir -p "$runners_dir" && tar -xzf "$tmp_dir/$runner_file" -C "$runners_dir"
            fi
            lutris_needs_restart="true"
            ;;
    esac

    # Cleanup tmp download
    debug_echo continue "Removing $tmp_dir/$runner_file..."
    rm "$tmp_dir/$runner_file"
}

# List available runners for download
runner_select_install() {
    # This function expects an element number for the array
    # runner_sources to be passed in as an argument
    if [ -z "$1" ]; then
        debug_echo exit "Script error:  The runner_select_install function expects a numerical argument. Aborting."
    fi

    # Store the url from the selected contributor
    contributor_url="${runner_sources[$1+1]}"

    # Check the provided contributor url to make sure we know how to handle it
    # To add new sources, add them here and handle in the if statement
    # just below and the runner_install function above
    case "$contributor_url" in
        https://api.github.com*)
            runner_url_type="github"
            ;;
        *)
            debug_echo exit "Script error:  Unknown api/url format in runner_sources array. Aborting."
            ;;
    esac

    # Fetch a list of runner versions from the selected contributor
    # To add new sources, handle them here, in the if statement
    # just above, and the runner_install function above
    if [ "$runner_url_type" = "github" ]; then
        runner_versions=($(curl -s "$contributor_url" | grep "browser_download_url" | awk '{print $2}' | xargs basename -a))
    else
        debug_echo exit "Script error:  Unknown api/url format in runner_sources array. Aborting."
    fi

    # Sanity check
    if [ "${#runner_versions[@]}" -eq 0 ]; then
        message warning "No runner versions were found.  The source API may be down or rate limited."
        return 1
    fi

    # Configure the menu
    menu_text_zenity="Select the Lutris runner you want to install:"
    menu_text_terminal="Select the Lutris runner you want to install:"
    menu_text_height="65"
    goback="Return to the runner management menu"
    unset menu_options
    unset menu_actions
    
    # Iterate through the versions, check if they are installed,
    # and add them to the menu options
    # To add new file extensions, handle them here and in
    # the runner_install function above
    for (( i=0; i<"$max_runners" && i<"${#runner_versions[@]}"; i++ )); do
        # Get the runner name minus the file extension
        case "${runner_versions[i]}" in
            *.tar.gz)
                runner_name="$(basename "${runner_versions[i]}" .tar.gz)"
                ;;
            *.tgz)
                runner_name="$(basename "${runner_versions[i]}" .tgz)"
                ;;
            *)
                debug_echo exit "Unknown archive filetype in runner_select_install function. Aborting."
                ;;
        esac

        # Add the runner names to the menu
        if [ -d "$runners_dir/$runner_name" ]; then
            menu_options+=("$runner_name    [installed]")
        else
            menu_options+=("$runner_name")
        fi
        menu_actions+=("runner_install $i")
    done

    # Complete the menu by adding the option to go back to the previous menu
    menu_options+=("$goback")
    menu_actions+=(":") # no-op

    # Calculate the total height the menu should be
    menu_height="$(("$menu_option_height" * "${#menu_options[@]}" + "$menu_text_height"))"
    if [ "$menu_height" -gt "400" ]; then
        menu_height="400"
    fi
    
    # Call the menu function.  It will use the options as configured above
    menu
}

# Called when the user is done managing runners
# Causes a return to the main menu
runner_manage_done() {
    managing_runners="false"
}

# Manage Lutris runners
runner_manage() {
    # Check if Lutris is installed
    if [ ! -x "$(command -v lutris)" ]; then
        message info "Lutris does not appear to be installed."
        return 0
    fi
    if [ ! -d "$runners_dir" ]; then
        message info "Lutris runners directory not found.  Unable to continue.\n\n$runners_dir"
        return 0
    fi
    
    # The runner management menu will loop until the user cancels
    managing_runners="true"

    while [ "$managing_runners" = "true" ]; do
        # Configure the menu
        menu_text_zenity="<b>This helper can manage your Lutris runners</b>\n\nChoose from the following options:"
        menu_text_terminal="This helper can manage your Lutris runners<\n\nChoose from the following options:"
        menu_text_height="100"

        # Configure the menu options
        delete="Remove an installed runner"
        back="Return to the main menu"
        unset menu_options
        unset menu_actions

        # Loop through the runner_sources array and create a menu item
        # for each one. Even numbered elements will contain the runner name
        for (( i=0; i<"${#runner_sources[@]}"; i=i+2 )); do
            # Set the options to be displayed in the menu
            menu_options+=("Install a runner from ${runner_sources[i]}")
            # Set the corresponding functions to be called for each of the options
            menu_actions+=("runner_select_install $i")
        done
        
        # Complete the menu by adding options to remove a runner
        # or go back to the previous menu
        menu_options+=("$delete" "$back")
        menu_actions+=("runner_select_delete" "runner_manage_done")

        # Calculate the total height the menu should be
        menu_height="$(("$menu_option_height" * "${#menu_options[@]}" + "$menu_text_height"))"
        
        # Call the menu function.  It will use the options as configured above
        menu
    done
    
    # Check if lutris needs to be restarted after making changes
    lutris_restart
}

#-------------------------- end runner functions -----------------------------#


# Get a random Penguin's Star Citizen referral code
referral_randomizer() {
    # Populate the referral codes array
    referral_codes=("STAR-4TZD-6KMM" "STAR-4XM2-VM99" "STAR-2NPY-FCR2" "STAR-T9Z9-7W6P" "STAR-VLBF-W2QR" "STAR-BYR6-YHMF" "STAR-3X2H-VZMX" "STAR-BRWN-FB9T" "STAR-FG6Y-N4Q4" "STAR-VLD6-VZRG" "STAR-T9KF-LV77" "STAR-4XHB-R7RF" "STAR-9NVF-MRN7" "STAR-3Q4W-9TC3" "STAR-3SBK-7QTT" "STAR-XFBT-9TTK" "STAR-F3H9-YPHN" "STAR-BYK6-RCCL" "STAR-XCKH-W6T7" "STAR-H292-39WK" "STAR-ZRT5-PJB7")
    # Pick a random array element. Scale a floating point number for
    # a more random distribution than simply calling RANDOM
    random_code="${referral_codes[$(awk '{srand($2); print int(rand()*$1)}' <<< "${#referral_codes[@]} $RANDOM")]}"

    message info "Your random Penguin's referral code is:\n\n$random_code\n\nThank you!"
}

# Toggle between the LIVE and PTU game directories for all helper functions
set_version() {
    if [ "$live_or_ptu" = "LIVE" ]; then
        live_or_ptu="PTU"
        message info "The helper will now target your Star Citizen PTU installation."
    elif [ "$live_or_ptu" = "PTU" ]; then
        live_or_ptu="LIVE"
        message info "The helper will now target your Star Citizen LIVE installation."
    else
        debug_echo continue "Unexpected game version provided.  Defaulting to the LIVE installation."
        live_or_ptu="LIVE"
    fi
}

quit() {
    exit 0
}


############################################################################
# MAIN
############################################################################

# Check if Zenity is available
has_zen=0
if [ -x "$(command -v zenity)" ]; then
    has_zen=1
fi

# Set some defaults
live_or_ptu="LIVE"
lutris_needs_restart="false"

# Loop the main menu until the user selects quit
while true; do
    # Configure the menu
    menu_text_zenity="<b><big>Welcome, fellow Penguin, to the Star Citizen LUG Helper!</big>\n\nThis helper is designed to help optimize your system for Star Citizen</b>\n\nYou may choose from the following options:"
    menu_text_terminal="Welcome, fellow Penguin, to the Star Citizen Linux Users Group Helper!\n\nThis helper is designed to help optimize your system for Star Citizen\nYou may choose from the following options:"
    menu_text_height="140"

    # Configure the menu options
    runners_msg="Manage Lutris Runners"
    sanitize_msg="Delete my Star Citizen USER folder and preserve my keybinds"
    mapcount_msg="Check vm.max_map_count for optimal performance"
    filelimit_msg="Check my open file descriptors limit"
    shaders_msg="Delete my shaders only"
    vidcache_msg="Delete my DXVK cache"
    randomizer_msg="Get a random Penguin's Star Citizen referral code"
    version_msg="Switch the helper between LIVE and PTU (default is LIVE)"
    quit_msg="Quit"
    
    # Set the options to be displayed in the menu
    menu_options=("$runners_msg" "$sanitize_msg" "$mapcount_msg" "$filelimit_msg" "$shaders_msg" "$vidcache_msg" "$randomizer_msg" "$version_msg" "$quit_msg")
    # Set the corresponding functions to be called for each of the options
    menu_actions=("runner_manage" "sanitize" "mapcount_set" "filelimit_set" "rm_shaders" "rm_vidcache" "referral_randomizer" "set_version" "quit")

    # Calculate the total height the menu should be
    menu_height="$(("$menu_option_height" * "${#menu_options[@]}" + "$menu_text_height"))"
    
    # Call the menu function.  It will use the options as configured above
    menu
done
