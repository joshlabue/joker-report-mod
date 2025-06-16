# Joker Report
**If you are not a tester, do not bother installing the mod. You will not be able to use it - the logging format is subject to change and no guarantees are made that logs will work upon release.**

Joker Report is currently under development. While the mod is open source, game sharing is not currently publicly available.

A read-only development server is available at https://dev.joker.report.

## Installation
Requirements:
- Balatro (STEAM ONLY)
- [Lovely](https://github.com/ethangreen-dev/lovely-injector) with [Steamodded](https://github.com/Steamodded/smods)

Install Steps:
1. Follow the [install steps for Lovely](https://github.com/ethangreen-dev/lovely-injector?tab=readme-ov-file#manual-installation)
2. Follow the [install steps for Steamodded](https://github.com/Steamodded/smods/wiki#how-to-install-steamodded)
3. Install Joker Report
    - Without Git (recommended):
        - [Download a zip](https://github.com/joshlabue/joker-report-mod/archive/refs/heads/main.zip) of the repository
        - Extract the zip into Balatro's mods folder
    - With Git:
        - Clone the repo into Balatro's mods folder:
            
                git clone https://github.com/joshlabue/joker-report-mod.git
4. Once installed, the mod should be in a folder called joker-report-mod (or something similar, the name does not need to exactly match), something like this:
    - Balatro
        - steam_autocloud.vdf
        - settings.jkr
        - Mods
            - joker-report-mod
                - JokerReport.json
                - main.lua
5. Verify that achievements are ENABLED in the mod menu's settings!
   
## Game Logs
Game logs are accessible in the joker_report folder in Balatro's data folder, next to the Mods folder.
- Windows: `%AppData%/Balatro/joker_report`
- macOS: `~/Library/Application Support/Balatro/joker_report`
- Linux (proton): `~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro`
