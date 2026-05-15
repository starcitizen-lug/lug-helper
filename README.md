# LUG Helper
**The official installer of the Star Citizen's Linux Users Group**  
Org: https://robertsspaceindustries.com/orgs/LUG  
Wiki: https://wiki.starcitizen-lug.org/  

### *Greetings, Space Penguin!*
This script helps you quickly and easily install and manage Star Citizen on Linux.  
It's maintained by the Star Citizen Linux Users Group org and community.

For our Quick Start Guide, troubleshooting steps, news, and other useful information such as input devices and head tracking setup, see our community's wiki link above.


## Installation

### Distro packages:
_These packages are maintained by the community_  

**Arch Linux:** https://aur.archlinux.org/packages/lug-helper/  
**Fedora:** https://copr.fedorainfracloud.org/coprs/jackgreiner/lug-helper  
**NixOS:** https://github.com/LovingMelody/nix-citizen  

### From source:
1. [Download](https://github.com/starcitizen-lug/lug-helper/releases) and extract the **.tar.gz** archive.
2. To run `lug-helper.sh` from your file manager:
    1. Navigate to the extracted lug-helper directory.
    2. Right click on `lug-helper.sh` and select **Run as a Program**.
4. To run `lug-helper.sh` from a terminal:
    1. Open your terminal and cd into the extracted lug-helper directory:  
       `cd /path/to/extracted/lug-helper` (List files with the `ls` command)
    3. Once you are in the directory containing lug-helper.sh, run it by typing:  
       `./lug-helper.sh`

_Dependencies: **bash**, **coreutils**, **curl**, **polkit** (these should be installed by default on most distributions)_  
_Winetricks Dependencies: **cabextract**, **unzip**_  
_Optional Dependencies: **zenity** (for GUI)_  


## Options
Zenity menus are used for a GUI experience with a fallback to terminal-based menus where Zenity is unavailable.  
Command line arguments are available for quickly launching functions from the terminal. (`./lug-helper.sh --help`)  

Configuration is saved in *$XDG_CONFIG_HOME/starcitizen-lug/*  


`Preflight Check`
- Runs a series of system optimization checks and offers to fix any issues
  - Checks that vm.max_map_count is set to at least 16777216
    - This sets the maxmimum number of "memory map areas" a process can have. While most applications need less than a thousand maps, Star Citizen requires access to more
  - Checks that the hard open file descriptors limit is set to at least 524288
    - This limits the maximum number of open files on your system.  On some Linux distributions, the default is set too low for Star Citizen

`Install Star Citizen Launcher`
- Installs the Star Citizen RSI Launcher using Wine

`Manage Wine Runners`
- Quickly install and delete custom Wine runners

`Manage DXVK`
- Update or switch to a different DXVK in the game's Wine prefix

`Maintenance and Troubleshooting`
- `Target a different Star Citizen installation`
  - Select a different wine prefix for the Helper to target in its operations

- `Update/Repair launch script`
  - Update the game launch script to the latest version or repair broken paths, icons, and .desktop files

- `Edit launch script`
  - Edit the game launch script

- `Open Wine prefix configuration`
  - Runs *winecfg* in the game's Wine prefix

- `Open Wine controller configuration`
  - Opens Wine's game controller configuration in the Wine prefix

- `Create joystick hidraw rules`
  - Creates udev rules to enable joystick hidraw access

- `Install PowerShell into Wine prefix`
  - Uses winetricks to install PowerShell

- `Update/Re-install RSI Launcher`
  - Re-install the latest version of the RSI Launcher

- `Display Helper & Star Citizen directories and files`
  - Show all the directories and files currently in use by both the Helper and Star Citizen

- `Reset Helper configs`
  - Delete the configs saved by the helper in *$XDG_CONFIG_HOME/starcitizen-lug/*

- `Uninstall Star Citizen`
  - Deletes the currently used Wine prefix and other installed files

`About and Support`
- Display information about the LUG Helper and links to our community





## Made with <3
**Author:** https://github.com/the-sane

❤️ Many thanks to everyone who has contributed to the project!  
You can view commit graphs for our contributors [here](https://github.com/starcitizen-lug/lug-helper/graphs/contributors).

Runner Downloader inspired by https://github.com/richardtatum/sc-runner-updater

## Contributing
Please read the [Contributor's Guide](https://github.com/starcitizen-lug/lug-helper?tab=contributing-ov-file).  
For a high level overview of the script's functions, please see [Code Structure and Overview](https://github.com/starcitizen-lug/lug-helper/wiki/Code-Structure-and-Overview) on the wiki.  
Packagers, please see the [Packager's Guide](https://github.com/starcitizen-lug/lug-helper/wiki/Packagers-Guide).  
