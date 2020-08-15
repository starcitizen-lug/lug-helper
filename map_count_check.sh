#!/usr/bin/env sh

# If Zenity is not available, print a message and exit
if ! command -v zenity &> /dev/null; then
	echo "WARNING: Zenity not found. Please see the installer's instructions on how to set vm.max_map_count manually, your you WILL experience crashes!"
	exit 0
fi

# If vm.max_map_count is already set, no need to do anything
if [ "$(cat /proc/sys/vm/max_map_count)" -ge 16777216 ]; then
    exit 0
fi

dialog() {
    zenity "$@" --icon-name='lutris' --width="400" --title="Star Citizen memory requirements check"
}

final_check() {
    if [ "$(cat /proc/sys/vm/max_map_count)" -lt 16777216 ]; then
        dialog --warning --text="As far as this script can detect, your system is not configured to allow Star Citizen to use more than ~8GB or memory. You will most likely experience crashes."
    fi
}

trap final_check EXIT

if grep -E -x -q "vm.max_map_count" /etc/sysctl.conf /etc/sysctl.d/*; then  
    if dialog --question --text="It looks like you already configured your system to work with Star Citizen, and saved the setting to persist across reboots. However, for some reason the persistence part did not work.\n\nFor now, would you like to enable the setting again until the next reboot?"
    then
        pkexec sh -c 'sysctl -w vm.max_map_count=16777216'
    fi
    exit 0
fi
      
once="Change setting until next reboot"
persist="Change setting and persist after reboot"
manual="Show me the commands; I'll handle it myself"

if dialog --question --text="Running Star Citizen requires changing a system setting. Otherwise, the game will crash after on areas with lots of geometry. As far as this script can detect, the setting has not been changed yet.\nNote: The setting is called vm.max_map_count and sould be set to 16777216 (minimum).\n\nWould you like to change the setting now?"; then
    # I tried to embed the command in the dialog and run the output, but
    # parsing variables with embedded quotes is an excercise in frustration.
    RESULT=$(dialog --list --radiolist --height="200" --column=" " --column="Command" "TRUE" "$once" \ "FALSE" "$persist" \ "FALSE" "$manual")
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
            	dialog --info --no-wrap --text="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.d/20-max_map_count.conf &amp;&amp; sysctl -p'"
            else
            	dialog --info --no-wrap --text="To change the setting (a kernel parameter) until next boot, run:\n\nsudo sh -c 'sysctl -w vm.max_map_count=16777216'\n\nTo persist the setting between reboots, run:\n\nsudo sh -c 'echo \"vm.max_map_count = 16777216\" >> /etc/sysctl.conf &amp;&amp; sysctl -p'"
            fi
            # Anyone who wants to do it manually doesn't need another warning
            trap - EXIT
            ;;
        *)
            echo "Dialog canceled or unknown option selected: $RESULT"
            ;;
      esac
      fi
