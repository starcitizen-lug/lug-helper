# LUG Helper
**Star Citizen's Linux Users Group Helper Script**  
https://robertsspaceindustries.com/orgs/LUG

### *Greetings, fellow Penguin!*
_**This script is designed to help you manage and optimize Star Citizen on Linux.**_

Zenity menus are used for a GUI experience with a fallback to terminal-based menus where Zenity is unavailable.  
Command line arguments are available for quickly launching functions from the terminal.  

Configuration is saved in *$XDG_CONFIG_HOME/starcitizen-lug/*  
Keybinds are backed up to *$XDG_CONFIG_HOME/starcitizen-lug/keybinds/*

## Options:

`Preflight Check`
- Runs a series of system optimization checks and offers to fix any issues.
  - Checks that vm.max_map_count is set to at least 16777216.
    - This sets the maxmimum number of "memory map areas" a process can have. While most applications need less than a thousand maps, Star Citizen requires access to more.
  - Checks that the hard open file descriptors limit is set to at least 524288.
    - This limits the maximum number of open files on your system.  On some Linux distributions, the default is set too low for Star Citizen.

`Install Star Citizen with Lutris`
- Launches Lutris and installs Star Citizen

`Install Star Citizen with Wine`
- Installs Star Citizen without Lutris, just using the system Wine

`Install PowerShell into Wine prefix`
- Uses winetricks to install PowerShell

`Manage Lutris Runners`
- Quickly install and delete Lutris wine runners

`Manage Lutris DXVK Versions`
- Quickly install and delete DXVK versions for Lutris

`Maintenance and Troubleshooting`
- `Switch the helper between LIVE/PTU/EPTU`
  - Target the LIVE, PTU, or EPTU installation for all operations.  Defaults to LIVE on each run.

`Target a different Star Citizen installation`
- Select a different wine prefix for the Helper to target in its operations  

- `Delete my Star Citizen USER folder and preserve my keybinds`
  - The helper will make backups of any exported keybinds, delete your Star Citizen USER folder, then restore your keybind files.
  - To export your keybinds from within the game, go to:
    - *Options->Keybindings->Control Profiles->Save Control Settings*
  - To re-import your keybinds from within the game, select them from the list:
    - *Options->Keybindings->Control Profiles*

- `Delete my shaders`
  - It is recommended to delete your shaders directory after each game update.
  - You will be prompted to confirm each directory before deletion, so you may choose which game version shaders you want cleared out.

- `Delete my DXVK cache`
  - A troubleshooting step that sometimes helps fix various issues and crashes.

- `Display Helper and Star Citizen directories`
  - Show all the directories currently in use by both the Helper and Star Citizen.

- `Reset Helper configs`
  - Delete the configs saved by the helper in *$XDG_CONFIG_HOME/starcitizen-lug/*

`Get a random Penguin's Star Citizen referral code`
- Display a referral code for a random member of the Star Citizen Linux Users Group.



## Installation:

**From Source:**
1. Download it! https://github.com/starcitizen-lug/lug-helper/releases
2. Extract it!
3. Run it!

**Arch Linux:** https://aur.archlinux.org/packages/lug-helper/

**NixOS:** https://github.com/LovingMelody/nix-citizen

_Dependencies: **bash**, **coreutils**, **curl**, **polkit** (these should be installed by default on most distributions)_  
_Optional Dependencies: **zenity** (for GUI)_  

## Contributors:
- https://github.com/Termuellinator
- https://github.com/pstn
- https://github.com/gort818
- https://github.com/victort
- https://github.com/Wrzlprnft
- https://github.com/ananace
- https://github.com/LovingMelody
- Runner Downloader inspired by https://github.com/richardtatum/sc-runner-updater
