#!/usr/bin/env sh

############################################################################
# Star Citizen vm.max_map_count checker
############################################################################
#
# This script checks to see if vm.max_map_count is set
# to the optimal value to prevent game crashes.
#
# If the setting is not set on the system, the script
# allows the user to set it temporarily or permanently.
#
#
# Supports zenity dialogs with a fallback to plain old text
#
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
		# call format: message 4 "TRUE" "List item 1" "FALSE" "List item 2" "FALSE" "List item 3"
		# IMPORTANT: Adjust the height value below based on the number of items listed in the menu
		margs=("--list" "--radiolist" "--height=165" "--text=Choose from the following options:" "--hide-header" "--column=" "--column=Option")
		;;
	    *)
		echo -e "Invalid message format.\n\nThe message function expects a numerical argument followed by string arguments.\n"
		read -n 1 -s -p "Press any key..."
		;;
        esac

        # Display the message
	if [ "$1" -eq 4 ]; then
	    # requires a space between the assembled arguments
	    shift 1   # drop the first numerical argument and shift the remaining up one
	    zenity "${margs[@]}" "$@" --width="400" --title="Star Citizen Memory Requirements Check"
	else
	    # no space between the assmebled arguments
	    shift 1   # drop the first numerical argument and shift the remaining up one
	    zenity "${margs[@]}""$@" --width="400" --title="Star Citizen Memory Requirements Check"
	fi
    else
        # Text based menu.  Does not work with message type 4 (zenity radio lists)
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

# Check if setting vm.max_map_count was successful
check_map_count() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        message 2 "As far as this script can detect, vm.max_map_count\nwas not successfully configured on your system.\n\nYou will most likely experience crashes."
    fi
}


##################################################################################
# Check vm.max_map_count for the correct setting and let the user fix it if needed
##################################################################################

# Check if Zenity is available
has_zen=0
if [ -x "$(command -v zenity)" ]; then
    has_zen=1
fi

# If vm.max_map_count is already set, no need to do anything
if [ "$(cat /proc/sys/vm/max_map_count)" -ge 16777216 ]; then
    message 1 "vm.max_map_count is already set to the optimal value.  You're all set!"
    exit 0
fi

trap check_map_count EXIT

if grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/* 2>/dev/null; then  
    if message 3 "It looks like you've already configured your system to work with Star Citizen\nand saved the setting to persist across reboots.\nHowever, for some reason the persistence part did not work.\n\nFor now, would you like to enable the setting again until the next reboot?"; then
        pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
    fi
    exit 0
fi

once="Change setting until next reboot"
persist="Change setting and persist after reboot"
manual="Show me the commands; I'll handle it myself"
quit="Quit"

newsysctl_msg="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl -p'"
oldsysctl_msg="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"

if message 3 "Running Star Citizen requires changing a system setting\nto give the game access to more than 8GB of memory.\n\nvm.max_map_count must be increased to at least 16777216\nto avoid crashes in areas with lots of geometry.\n\n\nAs far as this script can detect, the setting\nhas not been changed on your system.\n\nWould you like to change the setting now?"; then
    if [ "$has_zen" -eq 1 ]; then
        # zenity menu
        options=("TRUE" "$once" "FALSE" "$persist" "FALSE" "$manual")
        choice="$(message 4 "${options[@]}")"
        case "$choice" in
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
                    message 1 "$newsysctl_msg"
        	else
                    message 1 "$oldsysctl_msg"
        	fi
        	# Anyone who wants to do it manually doesn't need another warning
        	trap - EXIT
        	;;
            *)
        	;;
        esac
    else
        # text menu
        clear
	echo -e "\nThis script can change vm.max_map_count for you.\nChoose from the following options:\n"
	
        options=("$once" "$persist" "$manual" "$quit")
        PS3="Enter selection number or 'q' to quit: "

        select choice in "${options[@]}"
        do
            case "$choice" in
                "$once")
                    pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
                    break
                    ;;
                "$persist")
                    if [ -d "/etc/sysctl.d" ]; then
                        pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.d/20-max_map_count.conf && sysctl -p'
                    else
                        pkexec sh -c 'echo "vm.max_map_count = 16777216" >> /etc/sysctl.conf && sysctl -p'
                    fi
                    break
                    ;;
                "$manual")
		    clear
                    if [ -d "/etc/sysctl.d" ]; then
                        message 1 "$newsysctl_msg"
                    else
                        message 1 "$oldsysctl_msg"
                    fi
                    # Anyone who wants to do it manually doesn't need another warning
                    trap - EXIT
                    break
                    ;;
                "$quit")
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
