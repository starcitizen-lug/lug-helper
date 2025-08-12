# Contributor's Guide
### Project Goals
The LUG Helper is a purpose-built bash script for the [Star Citizen Linux Users Group](https://wiki.starcitizen-lug.org/). Our community is a diverse group of Penguins running many differnet Linux distros on all kinds of hardware. As such, ease of use and compatibility are primary focuses of the project.

The Helper is designed to be easy and intuitive for novice Penguins who may be using Linux for the very first time. It clearly communicates to the user what is being done and aims to provide working defaults without overwhelming the user with too many unnecessary choices.

### Pull Request Guidelines
With the above project goals in mind, please consider the following guidelines when submitting Pull Requests:
- Avoid overwhelming the user with choices and, instead, provide defaults that "Just Work".
- Any messages or options presented to the user should be clear and concise.
- The Helper should not make any changes to the user's system without first asking or notifying the user.
- Avoid duplicating code. Make use of the existing helper functions. See [Code Structure and Overview](#code-structure-and-overview) below.

### Code Syntax and Formatting Guidelines
- Match existing code styling and syntax for consistency and legibility.
- Stick to POSIX-compliant code where possible for portability.
- Where bashisms are necessary for functionality or because they vastly simplify code maintenance, check in which bash version the feature was introduced to make sure the code will work on older LTS distros.
- Where possible, code should be written to be easy to understand by someone who is moderately competent with shell script.
- Avoid overly simplified one-liners that are difficult to parse. Break it up.
- Please comment your code!


# Code Structure and Overview
What follows is a high level overview of the Helper's functions as of LUG Helper Version 4.3

## Setup
The setup portion at the top of the script:
- Performs dependency checks
- Initializes variables
- Sets configuration options for the rest of the script

## Helper abstractions
> [!note]
> These functions aim to provide easy access to actions frequently used by the Helper

#### Privilege escalation
* try_exec() 

#### Messaging and menu building
* debug_print() 
* message()
* progress_bar() 
* menu() 
* menu_loop_done() 

#### Fetch and set directories used by the Helper and Star Citizen
* getdirs() 

## Preflight Check Functions
> [!note]
> The preflight check is managed by one main function. It calls several auxiliary functions to perform its various actions

#### Main preflight check function
* preflight_check() 

#### Auxiliary preflight check functions
* wine_check() 
* memory_check() 
* avx_check() 
* mapcount_check() 
* mapcount_set() 
* mapcount_once() 
* mapcount_confirm() 
* filelimit_check() 
* filelimit_set() 
* filelimit_confirm() 

## Download functions
> [!note]
> Downloads are managed by one main function and a secondary function for each download type. It calls several auxiliary functions to perform its various actions

#### Main download managers
* download_manage() 
* runner_manage_wine() 

#### Auxiliary download functions
* download_select_install() 
* download_install() 
* download_select_delete() 
* download_delete() 
* post_download() 
* download_file() 
* lutris_restart() 
* download_file() 

## Maintenance menu functions
> [!note]
> The maintenance menu is managed by one main function. It calls several auxiliary functions to perform its various actions

#### Main maintenance menu
* maintenance_menu() 

#### Auxiliary maintenance functions
* switch_prefix()
* update_launcher()
* call_launch_script()
* edit_wine_launch_script() 
* display_dirs() 
* display_wiki() 
* reset_helper() 

## Install functions
> [!note]
> These functions handle game installation

* install_game_wine() 
* download_wine() 
* download_winetricks() 
* install_powershell()
* dxvk_update_wine() 

## Helper helper functions
> [!note]
> These helper functions perform actions needed by the Helper

* format_urls() 
* get_latest_release() 
* referral_randomizer() 
* quit() 

## Main
> [!note]
> The main logic of the script begins after all the functions are declared
