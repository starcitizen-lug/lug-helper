# Contributor's Guide
### Project Goals
The LUG Helper is a purpose-built bash script for the [Star Citizen Linux Users Group](https://wiki.starcitizen-lug.org/). Our community is a diverse group of Penguins running many differnet Linux distros on all kinds of hardware. As such, ease of use and compatibility are primary focuses of the project.

The Helper is designed to be easy and intuitive for novice Penguins who may be using Linux for the very first time. It clearly communicates to the user what is being done and aims to provide working defaults without overwhelming the user with too many unnecessary choices.

### Pull Request Guidelines
With the above project goals in mind, please consider the following guidelines when submitting Pull Requests:
- For significant changes, **please ask first** if it's desired or already being worked on.
- Avoid overwhelming the user with choices and, instead, provide defaults that "Just Work".
- Any messages or options presented to the user should be clear and concise.
- The Helper should not make any changes to the user's system without first asking or notifying the user.
- Avoid duplicating code. Make use of the existing helper functions. See [Code Structure and Overview](https://github.com/starcitizen-lug/lug-helper/wiki/Code-Structure-and-Overview).
- Please, **no AI-generated code**.

### Code Syntax and Formatting Guidelines
- Match existing code styling and syntax for consistency and legibility.
- Use POSIX-compliant code where possible for portability.
- Where non-POSIX, bash-specific syntax is necessary for functionality or because it vastly simplifies code maintenance, check in which bash version the feature was introduced. Verify that the syntax will work on LTS distros.
- Where possible, code should be easy to understand by someone moderately competent with shell script.
- Avoid overly simplified one-liners that are difficult to parse. Break it up.
- Please comment your code!

--- 
❤️ Many thanks to everyone who has [contributed](https://github.com/starcitizen-lug/lug-helper/graphs/contributors) to the project!
