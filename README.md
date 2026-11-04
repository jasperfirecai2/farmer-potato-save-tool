# farmer-potato-save-tool
A PowerShell tool for reading, editing, and re-signing local save files of Farmer Against Potatoes Idle. For personal, offline use only. Use at your own risk.

# fapi-save-tool

A PowerShell tool for reading, editing, and re-signing local

saves for **Farmer Against Potatoes Idle**.


## What it does

- Unpacks the gzip save file (`fapi-save.txt`).

- Parses the contents: `JSON + Base64(SHA256(salt + json))`.

- Allows you to add (or set) a value to specified JSON fields.

- Recalculates the signature.

- Repacks it into gzip in the same format used by the game.

- Creates a `.bak` backup file next to the original.

## Requirements

- Windows 10 / 11.

- PowerShell 5.1 (built into Windows) or PowerShell 7+.

- *Farmer Against Potatoes Idle* must be installed.

## Installation

1. Download Boost-Save.ps1 from this repository.

2. Place it in any folder, such as C:\Tools\.


When you run it for the first time, PowerShell may block the script. Allow it to run for the current session:


Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


### Usage 

Dry run (doesn’t write anything, just shows what will happen)


.\Boost-Save.ps1 -DryRun Add a value to FreeSoul and TotalSoul


.\Boost-Save.ps1 -Value 1000000000 Add to only one field


.\Boost-Save.ps1 -Value 500000000 -Fields FreeSoul Add to multiple fields at once

.\Boost-Save.ps1 -Value 500000000 -Fields ReincarnationLevel -MinIndex 2 Grab only matches past a certain index for duplicates


.\Boost-Save.ps1 -Value 1000000 -Fields FreeSoul,TotalSoul,SpentSoul Specify the path manually (if auto-detection didn’t work):


.\Boost-Save.ps1 -SaveDir “C:\path\to\save\folder” By default, the script adds to the current value rather than replacing it.


Disclaimer: This tool modifies local save files. Using it may violate the Steam Subscriber Agreement and/or the rules of a specific game.


The author is not responsible for:


corrupted or lost saves,


files being overwritten via Steam Cloud,


reset leaderboards, account flags, or bans,


any other consequences of using this tool.


Use at your own risk. Before using this tool, save a copy of your original save file in a safe place.

Translated using DeepL