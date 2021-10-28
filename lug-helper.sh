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
# - Easily install and remove Lutris wine Runners and DXVK versions.
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
# Contributor: https://github.com/gort818
# Contributor: https://github.com/victort
# Contributor: https://github.com/Wrzlprnft
# Runner Downloader inspired by:
# https://github.com/richardtatum/sc-runner-updater
############################################################################

# Check if script is run as root
if [ "$(id -u)" -eq 0 ]; then
    echo "This script is not supposed to be run as root!"
    exit 1
fi

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

# Use XDG base directories if defined
conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"

# .config subdirectory
conf_subdir="starcitizen-lug"

# Temporary directory
tmp_dir="$(mktemp -d --suffix=".lughelper")"
trap 'rm -r "$tmp_dir"' EXIT

######## Game Directories ##################################################

# The game's base directory name
sc_base_dir="StarCitizen"
# The default install location within a WINE prefix:
install_path="drive_c/Program Files/Roberts Space Industries/$sc_base_dir"

# The names of the live/ptu directories
live_dir="LIVE"
ptu_dir="PTU"

# Remaining directory paths are set at the end of the getdirs() function

######## Runners ###########################################################

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
    "/dev/null" "https://api.github.com/repos/gort818/wine-sc-lug/releases"
    "GloriousEggroll" "https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases"
)

######## DXVK ##############################################################

# Lutris dxvk directory
dxvk_dir="$data_dir/lutris/runtime/dxvk"
# URLs for downloading dxvk versions
# Elements in this array must be added in quoted pairs of: "description" "url"
# The first string in the pair is expected to contain the runner description
# The second is expected to contain the github api releases url
# ie. "Sporif Async" "https://api.github.com/repos/Sporif/dxvk-async/releases"
dxvk_sources=(
    "Sporif Async" "https://api.github.com/repos/Sporif/dxvk-async/releases"
    "/dev/null" "https://api.github.com/repos/gort818/dxvk/releases"
)

# Set a maximum number of versions to display from each download url
max_download_items=20

# Pixels to add for each Zenity menu option
# used to dynamically determine the height of menus
menu_option_height="25"

############################################################################

# Use logo installed by a packaged version of this script if available
# Otherwise, default to the logo in the same directory
if [ -f "/usr/share/pixmaps/lug-logo.png" ]; then
    lug_logo="/usr/share/pixmaps/lug-logo.png"
elif [ -f "lug-logo.png" ]; then
    lug_logo="lug-logo.png"
else
    lug_logo="info"
fi

# Github repo and script version info
repo="the-sane/lug-helper"
releases_url="https://github.com/the-sane/lug-helper/releases"
current_version="v1.11.1"

############################################################################
############################################################################


# Echo a formatted debug message to the terminal and optionally exit
# Accepts either "continue" or "exit" as the first argument
# followed by the string to be echoed
debug_print() {
    # This function expects two string arguments
    if [ "$#" -lt 2 ]; then
        printf "\nScript error:  The debug_print function expects two arguments. Aborting.\n"
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
            printf "lug-helper.sh: Unknown argument provided to debug_print function. Aborting.\n" 1>&2
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
        debug_print exit "Script error: The message function expects two arguments. Aborting."
    fi
    
    # Use zenity messages if available
    if [ "$use_zenity" -eq 1 ]; then
        case "$1" in
            "info")
                # info message
                # call format: message info "text to display"
                margs=("--info" "--window-icon=$lug_logo" "--no-wrap" "--text=")
                ;;
            "warning")
                # warning message
                # call format: message warning "text to display"
                margs=("--warning" "--window-icon=$lug_logo" "--text=")
                ;;
            "question")
                # question
                # call format: if message question "question to ask?"; then...
                margs=("--question" "--window-icon=$lug_logo" "--text=")
                ;;
            *)
                debug_print exit "Script Error: Invalid message type passed to the message function. Aborting."
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
                debug_print exit "Script Error: Invalid message type passed to the message function. Aborting."
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
# - The string "cancel_label" should contain the text of the cancel button.
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
        debug_print exit "Script error: The array 'menu_options' was not set\nbefore calling the menu function. Aborting."
    elif [ "${#menu_actions[@]}" -eq 0 ]; then
        debug_print exit "Script error: The array 'menu_actions' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$menu_text_zenity" ]; then
        debug_print exit "Script error: The string 'menu_text_zenity' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$menu_text_terminal" ]; then
        debug_print exit "Script error: The string 'menu_text_terminal' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$menu_height" ]; then
        debug_print exit "Script error: The string 'menu_height' was not set\nbefore calling the menu function. Aborting."
    elif [ -z "$cancel_label" ]; then
        debug_print exit "Script error: The string 'menu_height' was not set\nbefore calling the menu function. Aborting."
    fi
    
    # Use Zenity if it is available
    if [ "$use_zenity" -eq 1 ]; then
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
        choice="$(zenity --list --radiolist --width="480" --height="$menu_height" --text="$menu_text_zenity" --title="Star Citizen LUG Helper" --hide-header --cancel-label "$cancel_label" --window-icon=$lug_logo --column="" --column="Option" "${zen_options[@]}" 2>/dev/null)"

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

# Called when the user clicks cancel on a looping menu
# Causes a return to the main menu
menu_loop_done() {
    looping_menu="false"
}

# Get paths to the user's wine prefix, game directory, and a backup directory
getdirs() {
    # Sanity checks
    if [ ! -d "$conf_dir" ]; then
        message warning "Config directory not found. The Helper is unable to proceed.\n\n$conf_dir"
        return 1
    fi
    if [ ! -d "$conf_dir/$conf_subdir" ]; then
        mkdir -p "$conf_dir/$conf_subdir"
    fi

    # Check if the config files already exist
    if [ -f "$conf_dir/$conf_subdir/$wine_conf" ]; then
        wine_prefix="$(cat "$conf_dir/$conf_subdir/$wine_conf")"
        if [ ! -d "$wine_prefix" ]; then
            debug_print continue "The saved wine prefix does not exist, ignoring."
            wine_prefix=""
        fi
    fi
    if [ -f "$conf_dir/$conf_subdir/$game_conf" ]; then
        game_path="$(cat "$conf_dir/$conf_subdir/$game_conf")"
        if [ ! -d "$game_path" ] || [ "$(basename "$game_path")" != "$sc_base_dir" ]; then
            debug_print continue "Unexpected game path found in config file, ignoring."
            game_path=""
        fi
    fi

    # If we don't have the directory paths we need yet,
    # ask the user to provide them
    if [ -z "$wine_prefix" ] || [ -z "$game_path" ]; then
        message info "At the next screen, please select your Star Citizen WINE prefix.\nIt will be remembered for future use."
        if [ "$use_zenity" -eq 1 ]; then
            # Using Zenity file selection menus
            # Get the wine prefix directory
            if [ -z "$wine_prefix" ]; then
                wine_prefix="$(zenity --file-selection --directory --title="Select your Star Citizen WINE prefix directory" --filename="$HOME/Games/star-citizen" 2>/dev/null)"
                if [ "$?" -eq -1 ]; then
                    message warning "An unexpected error has occurred. The Helper is unable to proceed."
                    return 1
                elif [ -z "$wine_prefix" ]; then
                    # User clicked cancel
                    message warning "Operation cancelled.\nNo changes have been made to your game."
                    return 1
                fi
            fi

            # Get the game path
            if [ -z "$game_path" ]; then
                if [ -d "$wine_prefix/$install_path" ] && 
                       message question "Is this your Star Citizen game directory?\n\n$wine_prefix/$install_path"; then
                    game_path="$wine_prefix/$install_path"
                else
                    while game_path="$(zenity --file-selection --directory --title="Select your Star Citizen directory" --filename="$wine_prefix/$install_path" 2>/dev/null)"; do
                        if [ "$?" -eq -1 ]; then
                            message warning "An unexpected error has occurred. The Helper is unable to proceed."
                            return 1
                        elif [ "$(basename "$game_path")" != "$sc_base_dir" ]; then
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
                if [ -d "$wine_prefix/$install_path" ] && 
                       message question "Is this your Star Citizen game directory?\n\n$wine_prefix/$install_path"; then
                    game_path="$wine_prefix/$install_path"
                else
                    printf "\nEnter the full path to your Star Citizen installation directory (case sensitive)\n"
                    printf "ie. /home/USER/Games/star-citizen/drive_c/Program Files/Roberts Space Industries/StarCitizen\n"
                    while read -rp ": " game_path; do
                        if [ ! -d "$game_path" ]; then
                            printf "That directory is invalid or does not exist. Please try again.\n\n"
                        elif [ "$(basename "$game_path")" != "$sc_base_dir" ]; then
                            printf "You must enter the full path to the directory named '$sc_base_dir'\n\n"
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

    ######## Set remaining directory paths #####################################
    # $live_or_ptu is set in the set_version() function
    ############################################################################
    # The game's user directory
    user_dir="$game_path/$live_or_ptu/USER/Client/0"
    # The location within the USER directory to which the game exports keybinds
    keybinds_dir="$user_dir/Controls/Mappings"
    # Shaders directory
    shaders_dir="$user_dir/shaders"
    # dxvk cache file
    dxvk_cache="$game_path/$live_or_ptu/StarCitizen.dxvk-cache"
    # Where to store backed up keybinds
    backup_path="$conf_dir/$conf_subdir"
}

# Display all directories currently used by this helper and Star Citizen
display_dirs() {
    # Helper configs and keybinds
    if [ -d "$conf_dir/$conf_subdir" ]; then
        dirs_list+=("\n\nHelper configuration:\n$conf_dir/$conf_subdir\n\nKeybind backups:\n$conf_dir/$conf_subdir/keybinds")
    fi

    # Wine prefix
    if [ -f "$conf_dir/$conf_subdir/$wine_conf" ]; then
        dirs_list+="\n\nWine prefix:\n$(cat "$conf_dir/$conf_subdir/$wine_conf")"
    fi

    # Star Citizen installation
    if [ -f "$conf_dir/$conf_subdir/$game_conf" ]; then
        dirs_list+="\n\nStar Citizen game directory:\n$(cat "$conf_dir/$conf_subdir/$game_conf")"
    fi

    # Lutris runners
    if [ -d "$runners_dir" ]; then
        dirs_list+="\n\nLutris Runners:\n$runners_dir"
    fi

    # Lutris dxvk
    if [ -d "$runners_dir" ]; then
        dirs_list+="\n\nLutris DXVK Versions:\n$dxvk_dir"
    fi

    # Formatting
    message_heading="These directories are currently being used by this Helper and Star Citizen"
    if [ "$use_zenity" -eq 1 ]; then
        message_heading="<b>$message_heading</b>"
    fi

    message info "$message_heading\n${dirs_list[@]}"
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

    if message question "The following directory will be deleted:\n\n$user_dir\n\nDo you want to proceed?"; then
        # Back up keybinds
        if [ "$exported" -eq 1 ]; then
            debug_print continue "Backing up keybinds to $backup_path/keybinds..."
            mkdir -p "$backup_path/keybinds" && cp -r "$keybinds_dir/." "$backup_path/keybinds/"
        fi
        
        # Wipe the user directory
        debug_print continue "Wiping $user_dir..."
        rm -r "$user_dir"

        # Restore custom keybinds
        if [ "$exported" -eq 1 ]; then
            debug_print continue "Restoring keybinds..."
            mkdir -p "$keybinds_dir" && cp -r "$backup_path/keybinds/." "$keybinds_dir/"
            message info "To re-import your keybinds, select it in-game from the list:\nOptions->Keybindings->Control Profiles"
        fi

        message info "Your Star Citizen USER directory has been cleaned up!"
    fi
}

#--------------------- begin preflight check functions -----------------------#
#------------------------- begin mapcount functions --------------------------#

# Check if setting vm.max_map_count was successful
mapcount_confirm() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        preflight_results+=("WARNING: As far as this Helper can detect, vm.max_map_count\nwas not successfully configured on your system.\nYou will most likely experience crashes.")
    fi
}

# Sets vm.max_map_count for the current session only
mapcount_once() {
    preflight_actions+=('sysctl -w vm.max_map_count=16777216')
    preflight_results+=("vm.max_map_count was changed until the next boot.")
    preflight_followup+=("mapcount_confirm")
}

# Set vm.max_map_count
mapcount_set() {
    if [ -d "/etc/sysctl.d" ]; then
        # Newer versions of sysctl
        preflight_actions+=('printf "\n# Added by LUG-Helper:\nvm.max_map_count = 16777216\n" >> /etc/sysctl.d/20-max_map_count.conf && sysctl --system')
        preflight_results+=("The vm.max_map_count configuration has been appended to:\n/etc/sysctl.d/20-max_map_count.conf")
    else
        # Older versions of sysctl
        preflight_actions+=('printf "\n# Added by LUG-Helper:\nvm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p')
        preflight_results+=("The vm.max_map_count configuration has been appended to:\n/etc/sysctl.conf")
    fi
    
    # Verify that the setting took effect
    preflight_followup+=("mapcount_confirm")
}

# Check vm.max_map_count for the correct setting
mapcount_check() {
    mapcount="$(cat /proc/sys/vm/max_map_count)"
    # Add to the results and actions arrays
    if [ "$mapcount" -ge 16777216 ]; then
        # All good
        preflight_pass+=("vm.max_map_count is set to at least 16777216.")
    elif grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then
        # Was it supposed to have been set by sysctl?
        preflight_fail+=("vm.max_map_count is configured to at least 16777216 but the setting has not been loaded by your system.")
        # Add the function that will be called to change the configuration
        preflight_action_funcs+=("mapcount_once")

        # Add info for manually changing the setting
        preflight_manual+=("To change vm.max_map_count until the next reboot, run:\nsudo sysctl -w vm.max_map_count=16777216")
    else
        # The setting should be changed
        preflight_fail+=("vm.max_map_count is $mapcount\nand should be set to at least 16777216\nto give the game access to sufficient memory.")
        # Add the function that will be called to change the configuration
        preflight_action_funcs+=("mapcount_set")

        # Add info for manually changing the setting
        if [ -d "/etc/sysctl.d" ]; then
            # Newer versions of sysctl
            preflight_manual+=("To change vm.max_map_count permanently, add the following line to\n'/etc/sysctl.d/20-max_map_count.conf' and reload with 'sudo sysctl --system':\n    vm.max_map_count = 16777216\n\nOr, to change vm.max_map_count temporarily until next boot, run:\n    sudo sysctl -w vm.max_map_count=16777216")
        else
            # Older versions of sysctl
            preflight_manual+=("To change vm.max_map_count permanently, add the following line to\n'/etc/sysctl.conf' and reload with 'sudo sysctl -p':\n    vm.max_map_count = 16777216\n\nOr, to change vm.max_map_count temporarily until next boot, run:\n    sudo sysctl -w vm.max_map_count=16777216")
        fi
    fi
}

#-------------------------- end mapcount functions ---------------------------#

#------------------------ begin filelimit functions --------------------------#

# Check if setting the open file descriptors limit was successful
filelimit_confirm() {
    if [ "$(ulimit -Hn)" -lt 524288 ]; then
        preflight_results+=("WARNING: As far as this Helper can detect, the open files limit\nwas not successfully configured on your system.\nYou may experience crashes.")
    fi
}

# Set the open file descriptors limit
filelimit_set() {
    if [ -f "/etc/systemd/system.conf" ]; then
        # Using systemd
        # Append to the file
        preflight_actions+=('printf "\n# Added by LUG-Helper:\nDefaultLimitNOFILE=524288\n" >> /etc/systemd/system.conf && systemctl daemon-reexec')
        preflight_results+=("The open files limit configuration has been appended to:\n/etc/systemd/system.conf")
    elif [ -f "/etc/security/limits.conf" ]; then
        # Using limits.conf
        # Insert before the last line in the file
        preflight_actions+=('sed -i "\$i#Added by LUG-Helper:" /etc/security/limits.conf; sed -i "\$i* hard nofile 524288" /etc/security/limits.conf')
        preflight_results+=("The open files limit configuration has been appended to:\n/etc/security/limits.conf")
    else
        # Don't know what method to use
        preflight_results+=("This Helper is unable to detect the correct method of setting\nthe open file descriptors limit on your system.\n\nWe recommend manually configuring this limit to at least 524288.")
    fi

    # Verify that setting the limit was successful
    preflight_followup+=("filelimit_confirm")
}

# Check the open file descriptors limit
filelimit_check() {
    filelimit="$(ulimit -Hn)"

    # Add to the results and actions arrays
    if [ "$filelimit" -ge 524288 ]; then
        # All good
        preflight_pass+=("Hard open file descriptors limit is set to at least 524288.")
    else
        # The file limit should be changed
        preflight_fail+=("Your hard open file descriptors limit is $filelimit\nand should be set to at least 524288\nto increase the maximum number of open files.")
        # Add the function that will be called to change the configuration
        preflight_action_funcs+=("filelimit_set")

        # Add info for manually changing the settings
        if [ -f "/etc/systemd/system.conf" ]; then
            # Using systemd
            preflight_manual+=("To change your open file descriptors limit, add the following line to\n'/etc/systemd/system.conf':\n    DefaultLimitNOFILE=524288")
        elif [ -f "/etc/security/limits.conf" ]; then
            # Using limits.conf
            preflight_manual+=("To change your open file descriptors limit, add the following line to\n'/etc/security/limits.conf':\n    * hard nofile 524288")
        else
            # Don't know what method to use
            preflight_manual+=("This Helper is unable to detect the correct method of setting\nthe open file descriptors limit on your system.\n\nWe recommend manually configuring this limit to at least 524288.")
        fi
    fi
}

#------------------------- end filelimit functions ---------------------------#

# Check total system memory
memory_check() {
    memtotal="$(LC_NUMERIC=C awk '/MemTotal/ {printf "%.1f \n", $2/1024/1024}' /proc/meminfo)"
    if [ ${memtotal%.*} -ge "15" ]; then
        preflight_pass+=("Your system has $memtotal GB of memory.")  
    else
        preflight_fail+=("Your system has $memtotal GB of memory.\nWe recommend at least 16 GB to avoid crashes.")
    fi
}

# Check CPU for the required AVX extension
avx_check() {
    if grep -q "avx" /proc/cpuinfo; then
        preflight_pass+=("Your CPU supports the necessary AVX instruction set.")  
    else
        preflight_fail+=("Your CPU does not appear to support AVX instructions.\nThis requirement was added to Star Citizen in version 3.11")
    fi
}

#------------------------- end preflight check functions ---------------------#

# Delete the shaders directory
rm_shaders() {
    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu, or error
        return 0
    fi

    # Sanity check
    if [ ! -d "$shaders_dir" ]; then
        message warning "Shaders directory not found. There is nothing to delete!\n\n$shaders_dir"
        return 0
    fi

    # Delete the shader directory
    if message question "The following directory will be deleted:\n\n$shaders_dir\n\nDo you want to proceed?"; then
        debug_print continue "Deleting $shaders_dir..."
        rm -r "$shaders_dir"
        message info "Your shaders have been deleted!"
    fi
}

# Delete DXVK cache
rm_dxvkcache() {
    # Get/Set directory paths
    getdirs
    if [ "$?" -eq 1 ]; then
        # User cancelled and wants to return to the main menu
        # or there was an error
        return 0
    fi

    # Sanity check
    if [ ! -f "$dxvk_cache" ]; then
        message warning "Unable to find the DXVK cache file. There is nothing to delete!\n\n$dxvk_cache"
        return 0
    fi

    # Delete the cache file
    if message question "The following file will be deleted:\n\n$dxvk_cache\n\nDo you want to proceed?"; then
        debug_print continue "Deleting $dxvk_cache..."
        rm "$dxvk_cache"
        message info "Your DXVK cache has been deleted!"
    fi
}

# Restart lutris
lutris_restart() {
    if [ "$lutris_needs_restart" = "true" ] && [ "$(pgrep lutris)" ]; then
        if message question "Lutris must be restarted to detect the changes.\nWould you like this Helper to restart it for you?"; then
            debug_print continue "Restarting Lutris..."
            pkill -SIGTERM lutris && nohup lutris </dev/null &>/dev/null &
        fi
    fi
    lutris_needs_restart="false"
}

#------------------------- begin download functions ----------------------------#

# Display post download message or instructions if needed
# Expects the variables message_heading, post_download_msg1,
# post_download_msg2, and downloaded_item_name
post_download() {
    if [ "$trigger_post_download" = "true" ]; then
        message_heading="Download Complete"
        
        if [ "$use_zenity" -eq 1 ]; then
            message_heading="<b>$message_heading</b>"
            post_download_msg2="<i>$post_download_msg2</i>"
        fi
        message info "$message_heading\n\n$post_download_msg1\n\n$post_download_msg2\n$downloaded_item_name"
    fi
    trigger_post_download="false"
}

# Uninstall the selected item
download_delete() {
    # This function expects an index number for the array
    # installed_items to be passed in as an argument
    if [ -z "$1" ]; then
        debug_print exit "Script error:  The download_delete function expects an argument. Aborting."
    fi
    
    item_to_delete="$1"
    if message question "Are you sure you want to delete the following ${download_type}?\n\n${installed_items[$item_to_delete]}"; then
        rm -r "${installed_items[$item_to_delete]}"
        debug_print continue "Deleted ${installed_items[$item_to_delete]}"
        lutris_needs_restart="true"
    fi
}

# List installed items for deletion
download_select_delete() {
    # Configure the menu
    menu_text_zenity="Select the $download_type you want to remove:"
    menu_text_terminal="Select the $download_type you want to remove:"
    menu_text_height="65"
    goback="Return to the $download_type management menu"
    unset installed_items
    unset menu_options
    unset menu_actions
     
    # Create an array containing all directories in the download_dir
    for items_list in "$download_dir"/*; do
        if [ -d "$items_list" ]; then
            installed_items+=("$items_list")
        fi
    done

    # Create menu options for the installed items
    for (( i=0; i<"${#installed_items[@]}"; i++ )); do
        menu_options+=("$(basename "${installed_items[i]}")")
        menu_actions+=("download_delete $i")
    done

    # Complete the menu by adding the option to go back to the previous menu
    menu_options+=("$goback")
    menu_actions+=(":") # no-op

    # Calculate the total height the menu should be
    menu_height="$(($menu_option_height * ${#menu_options[@]} + $menu_text_height))"
    if [ "$menu_height" -gt "400" ]; then
        menu_height="400"
    fi

    # Set the label for the cancel button
    cancel_label="Go Back"

    # Call the menu function.  It will use the options as configured above
    menu
}

# Download and install the selected item
# Note: The variables download_versions, contributor_url, and download_url_type
# are expected to be set before calling this function
download_install() {
    # This function expects an index number for the array
    # download_versions to be passed in as an argument
    if [ -z "$1" ]; then
        debug_print exit "Script error:  The download_install function expects a numerical argument. Aborting."
    fi

    # Get the filename including file extension
    download_file="${download_versions[$1]}"

    # Get the selected item name minus the file extension
    # To add new file extensions, handle them here and in
    # the download_select_install function below
    case "$download_file" in
        *.tar.gz)
            download_name="$(basename "$download_file" .tar.gz)"
            ;;
        *.tgz)
            download_name="$(basename "$download_file" .tgz)"
            ;;
        *.tar.xz)
            download_name="$(basename "$download_file" .tar.xz)"
            ;;
        *)
            debug_print exit "Unknown archive filetype in download_install function. Aborting."
            ;;
    esac

    # Get the selected download url
    # To add new sources, handle them here and in the
    # download_select_install function below
    if [ "$download_url_type" = "github" ]; then
        download_url="$(curl -s "$contributor_url" | grep "browser_download_url.*$download_file" | cut -d \" -f4)"
    else
        debug_print exit "Script error:  Unknown api/url format in ${download_type}_sources array. Aborting."
    fi

    # Sanity check
    if [ -z "$download_url" ]; then
        message warning "Could not find the requested ${download_type}.  The source API may be down or rate limited."
        return 1
    fi

    # Download the item to the tmp directory
    debug_print continue "Downloading $download_url into $tmp_dir/$download_file..."
    if [ "$use_zenity" -eq 1 ]; then
        # Format the curl progress bar for zenity
        mkfifo "$tmp_dir/lugpipe"
        cd "$tmp_dir" && curl -#LO "$download_url" > "$tmp_dir/lugpipe" 2>&1 & curlpid="$!"
        stdbuf -oL tr '\r' '\n' < "$tmp_dir/lugpipe" | \
        grep --line-buffered -ve "100" | grep --line-buffered -o "[0-9]*\.[0-9]" | \
        (
            trap 'kill "$curlpid"' ERR
            zenity --progress --auto-close --title="Star Citizen LUG Helper" --text="Downloading ${download_type}.  This might take a moment.\n" 2>/dev/null
        )

        if [ "$?" -eq 1 ]; then
            # User clicked cancel
            debug_print continue "Download aborted. Removing $tmp_dir/$download_file..."
            rm "$tmp_dir/$download_file"
            rm "$tmp_dir/lugpipe"
            return 1
        fi
        rm "$tmp_dir/lugpipe"
    else
        # Standard curl progress bar
        (cd "$tmp_dir" && curl -LO "$download_url")
    fi

    # Sanity check
    if [ ! -f "$tmp_dir/$download_file" ]; then
        debug_print exit "Script error:  The requested $download_type file was not downloaded. Aborting"
    fi  

    # Extract the archive to the tmp directory
    debug_print continue "Extracting $download_type into $tmp_dir/$download_name..."
    if [ "$use_zenity" -eq 1 ]; then
        # Use Zenity progress bar
        mkdir "$tmp_dir/$download_name" && tar -xf "$tmp_dir/$download_file" -C "$tmp_dir/$download_name" | \
                zenity --progress --pulsate --no-cancel --auto-close --title="Star Citizen LUG Helper" --text="Extracting ${download_type}...\n" 2>/dev/null
    else
        mkdir "$tmp_dir/$download_name" && tar -xf "$tmp_dir/$download_file" -C "$tmp_dir/$download_name"
    fi

    # Check the contents of the extracted archive to determine the
    # directory structure we must create upon installation
    num_dirs=0
    num_files=0
    for extracted_item in "$tmp_dir/$download_name"/*; do
        if [ -d "$extracted_item" ]; then
            num_dirs="$((num_dirs+1))"
            extracted_dir="$(basename "$extracted_item")"
        elif [ -f "$extracted_item" ]; then
            num_files="$((num_files+1))"
        fi
    done

    # Create the correct directory structure and install the item
    if [ "$num_dirs" -eq 0 ] && [ "$num_files" -eq 0 ]; then
        # Sanity check
        message warning "The downloaded archive is empty. There is nothing to do."
    elif [ "$num_dirs" -eq 1 ] && [ "$num_files" -eq 0 ]; then
        # If the archive contains only one directory, install that directory
        debug_print continue "Installing $download_type into $download_dir/$extracted_dir..."
        if [ "$use_zenity" -eq 1 ]; then
            # Use Zenity progress bar
            mkdir -p "$download_dir" && cp -r "$tmp_dir"/"$download_name"/* "$download_dir" | \
                    zenity --progress --pulsate --no-cancel --auto-close --title="Star Citizen LUG Helper" --text="Installing ${download_type}...\n" 2>/dev/null
        else
            mkdir -p "$download_dir" && cp -r "$tmp_dir"/"$download_name"/* "$download_dir"
        fi

        # We need to restart Lutris for the download to be detected
        lutris_needs_restart="true"

        # Store the final name of the downloaded directory
        downloaded_item_name="$extracted_dir"

        # Trigger the post_download() function
        trigger_post_download="true"
    elif [ "$num_dirs" -gt 1 ] || [ "$num_files" -gt 0 ]; then
        # If the archive contains more than one directory or
        # one or more files, we must create a subdirectory
        debug_print continue "Installing $download_type into $download_dir/$download_name..."
        if [ "$use_zenity" -eq 1 ]; then
            # Use Zenity progress bar
            mkdir -p "$download_dir/$download_name" && cp -r "$tmp_dir"/"$download_name"/* "$download_dir"/"$download_name" | \
                    zenity --progress --pulsate --no-cancel --auto-close --title="Star Citizen LUG Helper" --text="Installing ${download_type}...\n" 2>/dev/null
        else
            mkdir -p "$download_dir/$download_name" && cp -r "$tmp_dir"/"$download_name"/* "$download_dir"/"$download_name"
        fi

        # We need to restart Lutris for the download to be detected
        lutris_needs_restart="true"

        # Store the final name of the downloaded directory
        downloaded_item_name="$download_name"

        # Trigger the post_download() function
        trigger_post_download="true"
    else
        # Some unexpected combination of directories and files
        debug_print exit "Script error:  Unexpected archive contents in download_install function. Aborting"
        exit 0
    fi

    # Cleanup tmp download
    debug_print continue "Cleaning up $tmp_dir/$download_file..."
    rm "$tmp_dir/$download_file"

    # Display any post-download messages or instructions
    post_download
}

# List available items for download
download_select_install() {
    # This function expects an element number for the sources array
    # to be passed in as an argument
    if [ -z "$1" ]; then
        debug_print exit "Script error:  The download_select_install function expects a numerical argument. Aborting."
    fi
    
    # Store info from the selected contributor
    contributor_name="${download_sources[$1]}"
    contributor_url="${download_sources[$1+1]}"

    # Check the provided contributor url to make sure we know how to handle it
    # To add new sources, add them here and handle in the if statement
    # just below and the download_install function above
    case "$contributor_url" in
        https://api.github.com*)
            download_url_type="github"
            ;;
        *)
            debug_print exit "Script error:  Unknown api/url format in ${download_type}_sources array. Aborting."
            ;;
    esac
    
    # For runners, check GlibC version against runner requirements
    if [ "download_type" = "runner" ] && [ "$contributor_name" = "/dev/null" ]; then
        required_glibc="2.33"
        system_glibc="$(ldd --version | awk '/ldd/{print $NF}')"

        if [ "$(bc <<< "$required_glibc > $system_glibc")" = "1" ]; then
            message warning "Your glibc version is incompatible with the selected runner.\n\nSystem glibc: v$system_glibc\nMinimum required glibc: v$required_glibc"
            return 1
        fi
    fi

    # Fetch a list of versions from the selected contributor
    # To add new sources, handle them here, in the if statement
    # just above, and the download_install function above
    if [ "$download_url_type" = "github" ]; then
        download_versions=($(curl -s "$contributor_url" | awk '/browser_download_url/ {print $2}' | grep -vE "*.sha512sum" | xargs basename -a))
    else
        debug_print exit "Script error:  Unknown api/url format in ${download_type}_sources array. Aborting."
    fi

    # Sanity check
    if [ "${#download_versions[@]}" -eq 0 ]; then
        message warning "No $download_type versions were found.  The source API may be down or rate limited."
        return 1
    fi

    # Configure the menu
    menu_text_zenity="Select the $download_type you want to install:"
    menu_text_terminal="Select the $download_type you want to install:"
    menu_text_height="65"
    goback="Return to the $download_type management menu"
    unset menu_options
    unset menu_actions
    
    # Iterate through the versions, check if they are installed,
    # and add them to the menu options
    # To add new file extensions, handle them here and in
    # the download_install function above
    for (( i=0; i<"$max_download_items" && i<"${#download_versions[@]}"; i++ )); do
        # Get the file name minus the extension
        case "${download_versions[i]}" in
            *.tar.gz)
                download_name="$(basename "${download_versions[i]}" .tar.gz)"
                ;;
            *.tgz)
                download_name="$(basename "${download_versions[i]}" .tgz)"
                ;;
            *.tar.xz)
                download_name="$(basename "${download_versions[i]}" .tar.xz)"
                ;;        
            *)
                debug_print exit "Unknown archive filetype in download_select_install function. Aborting."
                ;;
        esac

        # Add the file names to the menu
        if [ -d "$download_dir/$download_name" ]; then
            menu_options+=("$download_name    [installed]")
        else
            menu_options+=("$download_name")
        fi
        menu_actions+=("download_install $i")
    done

    # Complete the menu by adding the option to go back to the previous menu
    menu_options+=("$goback")
    menu_actions+=(":") # no-op

    # Calculate the total height the menu should be
    menu_height="$(($menu_option_height * ${#menu_options[@]} + $menu_text_height))"
    if [ "$menu_height" -gt "400" ]; then
        menu_height="400"
    fi
    
    # Set the label for the cancel button
    cancel_label="Go Back"
       
    # Call the menu function.  It will use the options as configured above
    menu
}

# Manage downloads
#
# This function expects the following variables to be set:
#
# - The string download_sources is a formatted array containing the URLs
#   of items to download. It should be pointed to the appropriate
#   array set at the top of the script using indirect expansion.
#   See runner_sources at the top and runner_manage() below for examples.
# - The string download_dir should contain the location the downloaded item
#   will be installed to.
# - The string "download_menu_heading" should contain the type of item
#   being downloaded.  It will appear in the menu heading.
# - The string "download_menu_description" should contain a description of
#   the item being downloaded.  It will appear in the menu subheading.
# - The integer "download_menu_height" specifies the height of the zenity menu.
#
# This function also expects one string argument containing the type of item to
# be downloaded.  ie. runner or dxvk.
#
# See runner_manage below for a configuration example.
download_manage() {
    # This function expects a string to be passed as an argument
    if [ -z "$1" ]; then
        debug_print exit "Script error:  The download_manage function expects a string argument. Aborting."
    fi
    # Check if Lutris is installed
    if [ ! -x "$(command -v lutris)" ]; then
        message info "Lutris does not appear to be installed."
        return 0
    fi
    if [ ! -d "$download_dir" ]; then
        message info "Lutris $download_type directory not found.  Unable to continue.\n\n$download_dir"
        return 0
    fi

    # Get the type of item we're downloading from the function arguments
    download_type="$1"

    # The download management menu will loop until the user cancels
    looping_menu="true"
    while [ "$looping_menu" = "true" ]; do
        # Configure the menu
        menu_text_zenity="<b><big>Manage Your $download_menu_heading</big>\n\n$download_menu_description</b>\n\nYou may choose from the following options:"
        menu_text_terminal="Manage Your $download_menu_heading\n\n$download_menu_description\nYou may choose from the following options:"
        menu_text_height="$download_menu_height"

        # Configure the menu options
        delete="Remove an installed $download_type"
        back="Return to the main menu"
        unset menu_options
        unset menu_actions

        # Loop through the download_sources array and create a menu item
        # for each one. Even numbered elements will contain the runner name
        for (( i=0; i<"${#download_sources[@]}"; i=i+2 )); do
            # Set the options to be displayed in the menu
            menu_options+=("Install a $download_type from ${download_sources[i]}")
            # Set the corresponding functions to be called for each of the options
            menu_actions+=("download_select_install $i")
        done
        
        # Complete the menu by adding options to uninstall an item
        # or go back to the previous menu
        menu_options+=("$delete" "$back")
        menu_actions+=("download_select_delete" "menu_loop_done")

        # Calculate the total height the menu should be
        menu_height="$(($menu_option_height * ${#menu_options[@]} + $menu_text_height))"
        
       # Set the label for the cancel button
       cancel_label="Go Back"
       
        # Call the menu function.  It will use the options as configured above
        menu
    done
    
    # Check if lutris needs to be restarted after making changes
    lutris_restart
}

#-------------------------- end download functions -----------------------------#

# Configure the download_manage function for runners
runner_manage() {
    # Set some defaults
    lutris_needs_restart="false"
    trigger_post_download="false"

    # Use indirect expansion to point download_sources
    # to the runner_sources array set at the top of the script
    declare -n download_sources=runner_sources
    download_dir="$runners_dir"

    # Configure the text displayed in the menus
    download_menu_heading="Lutris Runners"
    download_menu_description="The runners listed below are wine builds created for Star Citizen"
    download_menu_height="140"

    # Set the post download instructions
    post_download_msg1="Select the runner in Lutris from the dropdown menu:"
    post_download_msg2="Configure->Runner Options->Wine version"

    # Call the download_manage function with the above configuration
    # The argument passed to the function is used for special handling
    # and displayed in the menus and dialogs.
    download_manage "runner"
}

# Configure the download_manage function for dxvks
dxvk_manage() {
    # Set some defaults
    lutris_needs_restart="false"
    trigger_post_download="false"

    # Use indirect expansion to point download_sources
    # to the dxvk_sources array set at the top of the script
    declare -n download_sources=dxvk_sources
    download_dir="$dxvk_dir"

    # Configure the text displayed in the menus
    download_menu_heading="DXVK Versions"
    download_menu_description="The DXVK versions below may help improve game performance"
    download_menu_height="140"

    # Set the post download instructions
    post_download_msg1="Type the DXVK folder name in your Lutris settings:"
    post_download_msg2="Configure->Runner Options->DXVK version"

    # Call the download_manage function with the above configuration
    # The argument passed to the function is used for special handling
    # and displayed in the menus and dialogs.
    download_manage "dxvk"
}

#-------------------------- end dxvk functions -----------------------------#

# Check that the system is optimized for Star Citizen
preflight_check() {
    # Initialize variables
    unset preflight_pass
    unset preflight_fail
    unset preflight_action_funcs
    unset preflight_actions
    unset preflight_results
    unset preflight_manual
    unset preflight_followup
    
    # Call the optimization functions to perform the checks
    memory_check
    avx_check
    mapcount_check
    filelimit_check

    # Populate info strings with the results and add formatting
    if [ "${#preflight_pass[@]}" -gt 0 ]; then
        preflight_pass_string="Passed Checks:"
        for (( i=0; i<"${#preflight_pass[@]}"; i++ )); do
            preflight_pass_string="$preflight_pass_string\n- ${preflight_pass[i]//\\n/\\n    }"
        done
        # Add extra newlines if there are also failures to report
        if [ "${#preflight_fail[@]}" -gt 0 ]; then
            preflight_pass_string="$preflight_pass_string\n\n"
        fi
    fi
    if [ "${#preflight_fail[@]}" -gt 0 ]; then
        preflight_fail_string="Failed Checks:"
        for (( i=0; i<"${#preflight_fail[@]}"; i++ )); do
            if [ "$i" -eq 0 ]; then
                preflight_fail_string="$preflight_fail_string\n- ${preflight_fail[i]//\\n/\\n    }"
            else
                preflight_fail_string="$preflight_fail_string\n\n- ${preflight_fail[i]//\\n/\\n    }"
            fi
        done
    fi
    for (( i=0; i<"${#preflight_manual[@]}"; i++ )); do
        if [ "$i" -eq 0 ]; then
            preflight_manual_string="${preflight_manual[i]}"
        else
            preflight_manual_string="$preflight_manual_string\n\n${preflight_manual[i]}"
        fi
    done

    # Display the results of the preflight check
    if [ -z "$preflight_fail_string" ]; then
        # Formatting
        message_heading="Preflight Check Complete"
        if [ "$use_zenity" -eq 1 ]; then
            message_heading="<b>$message_heading</b>"
        fi
        
        message info "$message_heading\n\nYour system is optimized for Star Citizen!\n\n$preflight_pass_string"
    else
        if [ -z "$preflight_action_funcs" ]; then
            message warning "$preflight_pass_string$preflight_fail_string"
        elif message question "$preflight_pass_string$preflight_fail_string\n\nWould you like configuration issues to be fixed for you?"; then
            # Call functions to build fixes for any issues found
            for (( i=0; i<"${#preflight_action_funcs[@]}"; i++ )); do
                ${preflight_action_funcs[i]}
            done
            # Populate a string of actions to be executed
            for (( i=0; i<"${#preflight_actions[@]}"; i++ )); do
                if [ "$i" -eq 0 ]; then
                    preflight_actions_string="${preflight_actions[i]}"
                else
                    preflight_actions_string="$preflight_actions_string; ${preflight_actions[i]}"
                fi
            done

            # Execute the actions set by the functions
            if [ ! -z "$preflight_actions_string" ]; then
                # Use pollkit's pkexec for gui with a fallback to sudo
                if [ -x "$(command -v pkexec)" ]; then
                    pkexec sh -c "$preflight_actions_string"
                else
                    sudo sh -c "$preflight_actions_string"
                fi
            fi

            # Call any followup functions
            for (( i=0; i<"${#preflight_followup[@]}"; i++ )); do
                ${preflight_followup[i]}
            done

            # Populate the results string
            for (( i=0; i<"${#preflight_results[@]}"; i++ )); do
                if [ "$i" -eq 0 ]; then
                    preflight_results_string="${preflight_results[i]}"
                else
                    preflight_results_string="$preflight_results_string\n\n${preflight_results[i]}"
                fi
            done

            # Display the results
            message info "$preflight_results_string"
        else
            # User declined to automatically fix configuration issues
            # Show manual configuration options
            if [ ! -z "$preflight_manual_string" ]; then
                message info "$preflight_manual_string"
            fi
        fi
    fi
}

# Show maintenance/troubleshooting options
maintenance_menu() {
    # Loop the menu until the user selects quit
    looping_menu="true"
    while [ "$looping_menu" = "true" ]; do
        # Configure the menu
        menu_text_zenity="<b><big>Game Maintenance and Troubleshooting</big></b>\n\nYou may choose from the following options:"
        menu_text_terminal="Game Maintenance and Troubleshooting\n\nYou may choose from the following options:"
        menu_text_height="100"

        # Configure the menu options
        version_msg="Switch the Helper between LIVE and PTU  (Currently: $live_or_ptu)"
        sanitize_msg="Delete my Star Citizen USER folder and preserve my keybinds"
        shaders_msg="Delete my shaders folder only (Do this after each game update)"
        vidcache_msg="Delete my DXVK cache"
        dirs_msg="Display Helper and Star Citizen directories"
        reset_msg="Reset Helper configs"
        quit_msg="Return to the main menu"
        
        # Set the options to be displayed in the menu
        menu_options=("$version_msg" "$sanitize_msg" "$shaders_msg" "$vidcache_msg" "$dirs_msg" "$reset_msg" "$quit_msg")
        # Set the corresponding functions to be called for each of the options
        menu_actions=("set_version" "sanitize" "rm_shaders" "rm_dxvkcache" "display_dirs" "reset_helper" "menu_loop_done")

        # Calculate the total height the menu should be
        menu_height="$(($menu_option_height * ${#menu_options[@]} + $menu_text_height))"
       
       # Set the label for the cancel button
       cancel_label="Go Back"
       
        # Call the menu function.  It will use the options as configured above
        menu
    done
}

# Get a random Penguin's Star Citizen referral code
referral_randomizer() {
    # Populate the referral codes array
    referral_codes=("STAR-4TZD-6KMM" "STAR-4XM2-VM99" "STAR-2NPY-FCR2" "STAR-T9Z9-7W6P" "STAR-VLBF-W2QR" "STAR-BYR6-YHMF" "STAR-3X2H-VZMX" "STAR-BRWN-FB9T" "STAR-FG6Y-N4Q4" "STAR-VLD6-VZRG" "STAR-T9KF-LV77" "STAR-4XHB-R7RF" "STAR-9NVF-MRN7" "STAR-3Q4W-9TC3" "STAR-3SBK-7QTT" "STAR-XFBT-9TTK" "STAR-F3H9-YPHN" "STAR-BYK6-RCCL" "STAR-XCKH-W6T7" "STAR-H292-39WK" "STAR-ZRT5-PJB7" "STAR-GMBP-SH9Y" "STAR-PLWB-LMFY" "STAR-TNZN-H4ZT" "STAR-T5G5-L2GJ" "STAR-6TPV-7QH2" "STAR-THHD-TV3Y" "STAR-7ZFS-PK2L" "STAR-SRQN-43TB" "STAR-9TDG-D4H9" "STAR-BPH3-THJC" "STAR-HL3M-R5KC" "STAR-GBS5-LTVB" "STAR-CJ3Y-KZZ4" "STAR-5GRM-7HBY" "STAR-G2GX-Y2QJ" "STAR-YWY3-H4XX" "STAR-6VGM-PTKC" "STAR-T6MZ-QFHX" "STAR-T2K6-LXFW" "STAR-XN25-9CJJ" "STAR-47V3-4QGB")
    # Pick a random array element. Scale a floating point number for
    # a more random distribution than simply calling RANDOM
    random_code="${referral_codes[$(awk '{srand($2); print int(rand()*$1)}' <<< "${#referral_codes[@]} $RANDOM")]}"

    message info "Your random Penguin's referral code is:\n\n$random_code\n\nThank you!"
}

# Toggle between the LIVE and PTU game directories for all Helper functions
set_version() {
    if [ "$live_or_ptu" = "$live_dir" ]; then
        live_or_ptu="$ptu_dir"
        message info "The Helper will now target your Star Citizen PTU installation."
    elif [ "$live_or_ptu" = "$ptu_dir" ]; then
        live_or_ptu="$live_dir"
        message info "The Helper will now target your Star Citizen LIVE installation."
    else
        debug_print continue "Unexpected game version provided.  Defaulting to the LIVE installation."
        live_or_ptu="$live_dir"
    fi
}

# Delete the helper's config directory
reset_helper() {
    # Delete the shader directory
    if message question "All config files will be deleted from:\n\n$conf_dir/$conf_subdir\n\nDo you want to proceed?"; then
        debug_print continue "Deleting $conf_dir/$conf_subdir/*.conf..."
        rm "$conf_dir/$conf_subdir/"*.conf
        message info "The Helper has been reset!"
    fi
}

# Get the latest release version of a repo. Expects "user/repo_name" as input
# Credits for this go to https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
get_latest_release() {
    # Sanity check
    if [ "$#" -lt 1 ]; then
        debug_print exit "Script error: The get_latest_release function expects one argument. Aborting."
    fi
    
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
        grep '"tag_name":' |                                            # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

quit() {
    exit 0
}


############################################################################
# MAIN
############################################################################

# Check if Zenity is available
use_zenity=0
if [ -x "$(command -v zenity)" ]; then
    use_zenity=1
fi

# Set defaults
live_or_ptu="$live_dir"

# Check if a newer verison of the script is available
latest_version="$(get_latest_release "$repo")"

if [ "$latest_version" != "$current_version" ]; then
    if [ "$use_zenity" -eq 1 ]; then
        releases_url_formatted="<a href='$releases_url'>$releases_url</a>"
    else
        releases_url_formatted="$releases_url"
    fi
    
    message info "The latest version of the LUG Helper is $latest_version\nYou are using $current_version\n\nYou can download new releases here:\n$releases_url_formatted"
fi

# If invoked with command line arguments, process them and exit
if [ "$#" -gt 0 ]; then
    while [ "$#" -gt 0 ]
    do
        # Victor_Tramp expects the spanish inquisition.
        case "$1" in
            --help | -h )
                printf "Star Citizen Linux Users Group Helper Script
Usage: lug-helper <options>
  -p, --preflight-check     Run system optimization checks
  -m, --manage-runners      Install or remove Lutris runners
  -u, --delete-user-folder  Delete Star Citizen USER folder, preserving keybinds
  -s, --delete-shaders      Delete Star Citizen shaders directory
  -c, --delete-dxvk-cache   Delete Star Citizen dxvk cache file
  -t, --target=[live|ptu]   Target LIVE or PTU (default live)
  -g, --use-gui=[yes|no]    Use Zenity GUI if available (default yes)
  -r, --get-referral        Get a random LUG member's Star Citizen referral code
  -d, --show-directories    Show all Star Citizen and LUG Helper directories
  -x, --reset-helper        Delete saved lug-helper configs
"
                exit 0
                ;;
            --preflight-check | -p )
                cargs+=("preflight_check")
                ;;
            --manage-runners | -m )
                cargs+=("runner_manage")
                ;;
            --delete-user-folder | -u )
                cargs+=("sanitize")
                ;;
            --delete-shaders | -s )
                cargs+=("rm_shaders")
                ;;
            --delete-dxvk-cache | -c )
                cargs+=("rm_dxvkcache")
                ;;
            --target=* | -t=* )
                live_or_ptu="$(echo "$1" | cut -d'=' -f2)"
                if [ "$live_or_ptu" = "live" ] || [ "$live_or_ptu" = "LIVE" ]; then
                    live_or_ptu="$live_dir"
                elif [ "$live_or_ptu" = "ptu" ] || [ "$live_or_ptu" = "PTU" ]; then
                    live_or_ptu="$ptu_dir"
                else
                    printf "$0: Invalid option '$1'\n"
                    exit 0
                fi
                ;;
            --use-gui=* | -g=* )
                # If zenity is unavailable, it has already been set to 0
                # and this setting has no effect
                if [ -x "$(command -v zenity)" ]; then
                    use_zenity="$(echo "$1" | cut -d'=' -f2)"
                    if [ "$use_zenity" = "yes" ] || [ "$use_zenity" = "YES" ] || [ "$use_zenity" = "1" ]; then
                        use_zenity=1
                    elif [ "$use_zenity" = "no" ] || [ "$use_zenity" = "NO" ] || [ "$use_zenity" = "0" ]; then
                        use_zenity=0
                    else
                        printf "$0: Invalid option '$1'\n"
                        exit 0
                    fi
                fi
                ;;
            --get-referral | -r )
                cargs+=("referral_randomizer")
                ;;
            --show-directories | -d )
                cargs+=("display_dirs")
                ;;
            --reset-helper | -x )
                cargs+=("reset_helper")
                ;;
            * )
                printf "$0: Invalid option '$1'\n"
                exit 0
                ;;
        esac
        # Shift forward to the next argument and loop again
        shift
    done

    # Call the requested functions and exit
    if [ "${#cargs[@]}" -gt 0 ]; then
        for (( i=0; i<"${#cargs[@]}"; i++ )); do
            ${cargs[i]}
        done
        exit 0
    fi
fi

# Loop the main menu until the user selects quit
while true; do
    # Configure the menu
    menu_text_zenity="<b><big>Welcome, fellow Penguin, to the Star Citizen LUG Helper!</big>\n\nThis Helper is designed to help optimize your system for Star Citizen</b>\n\nYou may choose from the following options:"
    menu_text_terminal="Welcome, fellow Penguin, to the Star Citizen Linux Users Group Helper!\n\nThis Helper is designed to help optimize your system for Star Citizen\nYou may choose from the following options:"
    menu_text_height="140"

    # Configure the menu options
    preflight_msg="Preflight Check (System Optimization)"
    runners_msg="Manage Lutris Runners"
    dxvk_msg="Manage DXVK Versions"
    maintenance_msg="Maintenance and Troubleshooting"
    randomizer_msg="Get a random Penguin's Star Citizen referral code"
    quit_msg="Quit"
    
    # Set the options to be displayed in the menu
    menu_options=("$preflight_msg" "$runners_msg" "$dxvk_msg" "$maintenance_msg" "$randomizer_msg" "$quit_msg")
    # Set the corresponding functions to be called for each of the options
    menu_actions=("preflight_check" "runner_manage" "dxvk_manage" "maintenance_menu" "referral_randomizer" "quit")

    # Calculate the total height the menu should be
    menu_height="$(($menu_option_height * ${#menu_options[@]} + $menu_text_height))"
    
    # Set the label for the cancel button
    cancel_label="Quit"
    
    # Call the menu function.  It will use the options as configured above
    menu
done
