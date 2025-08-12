# LUG Helper
**Star Citizen's Linux Users Group Helper Script**  
https://robertsspaceindustries.com/orgs/LUG

### *Greetings, fellow Penguin!*
_**This script is designed to help you manage and optimize Star Citizen on Linux.**_

Zenity menus are used for a GUI experience with a fallback to terminal-based menus where Zenity is unavailable.  
Command line arguments are available for quickly launching functions from the terminal.  

Configuration is saved in *$XDG_CONFIG_HOME/starcitizen-lug/*  
Keybinds are backed up to *$XDG_CONFIG_HOME/starcitizen-lug/keybinds/*

## Options

`Preflight Check`
- Runs a series of system optimization checks and offers to fix any issues.
  - Checks that vm.max_map_count is set to at least 16777216.
    - This sets the maxmimum number of "memory map areas" a process can have. While most applications need less than a thousand maps, Star Citizen requires access to more.
  - Checks that the hard open file descriptors limit is set to at least 524288.
    - This limits the maximum number of open files on your system.  On some Linux distributions, the default is set too low for Star Citizen.

`Install Star Citizen`
- Installs Star Citizen using Wine

`Manage Wine Runners`
- Quickly install and delete custom Wine runners

`Update DXVK`
- Update DXVK in the game's Wine prefix

`Maintenance and Troubleshooting`
- `Target a different Star Citizen installation`
  - Select a different wine prefix for the Helper to target in its operations

- `Update launch script`
  - Update the game launch script to the latest version

- `Edit launch script`
  - Edit the game launch script

- `Open Wine prefix configuration`
  - Runs *winecfg* in the game's Wine prefix

- `Open Wine controller configuration`
  - Opens Wine's game controller configuration in the Wine prefix

- `Install PowerShell into Wine prefix`
  - Uses winetricks to install PowerShell

- `Display Helper and Star Citizen directories`
  - Show all the directories currently in use by both the Helper and Star Citizen.

- `Reset Helper configs`
  - Delete the configs saved by the helper in *$XDG_CONFIG_HOME/starcitizen-lug/*

`Get a random Penguin's Star Citizen referral code`
- Display a referral code for a random member of the Star Citizen Linux Users Group.



## Installation

**From Source:**
1. Download it! https://github.com/starcitizen-lug/lug-helper/releases
2. Extract it!
3. Run it!

**Arch Linux:** https://aur.archlinux.org/packages/lug-helper/  
**NixOS:** https://github.com/LovingMelody/nix-citizen  
**Fedora:** https://copr.fedorainfracloud.org/coprs/jackgreiner/lug-helper  

_Dependencies: **bash**, **coreutils**, **curl**, **polkit** (these should be installed by default on most distributions)_  
_Winetricks Dependencies: **cabextract**, **unzip**_  
_Optional Dependencies: **zenity** (for GUI)_  

## Made with <3
#### Author:
- https://github.com/the-sane
#### Contributors:
- https://github.com/Termuellinator
- https://github.com/pstn
- https://github.com/gort818
- https://github.com/victort
- https://github.com/Wrzlprnft
- https://github.com/ananace
- https://github.com/LovingMelody
- https://github.com/mactan-sc
- https://github.com/ProjectSynchro
- Runner Downloader inspired by https://github.com/richardtatum/sc-runner-updater

❤️ Many thanks to everyone who has contributed to the project!  
You can view commit graphs for the Helper's contributors [here](https://github.com/starcitizen-lug/lug-helper/graphs/contributors).

## Contributing
Please read the [Contributor's Guide](https://github.com/starcitizen-lug/lug-helper?tab=contributing-ov-file).  
For a high level overview of the script's functions, please see [Code Structure and Overview](https://github.com/starcitizen-lug/lug-helper/wiki/Code-Structure-and-Overview) on the wiki.  
Packagers, please see the [Packager's Guide](https://github.com/starcitizen-lug/lug-helper/wiki/Packagers-Guide).  
