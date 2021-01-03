# lug-helper
**Star Citizen's Linux Users Group Helper Script**

https://robertsspaceindustries.com/orgs/LUG

*Greetings, fellow Penguin!*

This script is designed to help you optimize your system to run Star Citizen as smoothly as possible. It presents options to check your system for optimal settings and helps you change them as needed to prevent game crashes.

Additionally, it gives you an easy way to manage your Lutris WINE runners.  It can also wipe your Star Citizen *USER* folder as is recommended by CIG after major version updates. It will back up your exported keybinds, delete your *USER* folder, then restore your keybind file(s).

Zenity menus are used for a GUI experience with a fallback to terminal-based menus where Zenity is unavailable. The game directory paths provided by the user on first run are saved in *$XDG_CONFIG_HOME/starcitizen-lug*.

## Options:

`Manage Lutris Runners`
- Quickly install and delete Lutris wine runners

`Delete my Star Citizen USER folder and preserve my keybinds`
- The helper will make backups of any exported keybinds, delete your Star Citizen USER folder, then restore your keybind files.
- To export your keybinds from within the game, go to:
  - *Options->Keybindings->Control Profiles->Save Control Settings*
- To re-import your keybinds from within the game, select them from the list:
  - *Options->Keybindings->Control Profiles*

`Check vm.max_map_count for optimal performance`
- We recommend setting this to at least 16777216 to give the game access to sufficient memory.
- The helper will offer to set it for you or show you the commands to do it yourself.

`Check my open file descriptors limit`
- We recommend setting the hard open files limit to at least 524288.
- The helper will offer to set it for you and try to auto-detect the correct method to do so.
- It is able to update either */etc/systemd/system.conf* or */etc/security/limits.conf*

`Delete my shaders only`
- Sometimes all you need to do between major version updates is delete your shaders directory.

`Delete my DXVK cache`
- A troubleshooting step that sometimes helps fix various issues and crashes.

`Switch the helper between LIVE and PTU`
- Toggle between targeting LIVE or PTU for all of the above options.  Defaults to LIVE on each run.
