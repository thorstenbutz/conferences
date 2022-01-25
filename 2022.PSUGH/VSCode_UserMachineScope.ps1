#######################################
## VSCode setup: User vs machine scope 
#######################################

## Search
winget search vscode

## Simple setup via moniker (defaults to a user install)
winget install vscode 

## Explicit installation
winget install --id Microsoft.VisualStudioCode --scope user
winget install --id Microsoft.VisualStudioCode --scope machine

## First restart the shell!
Get-Command -name code*

## In case you want to search for the files
Get-ChildItem  -Recurse -Filter code.exe -file -Force -ErrorAction SilentlyContinue | Select-Object -Property Mode,Length, Fullname
