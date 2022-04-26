######################
## The python problem
######################

## An app execution alias is preconfigured with Windows which points to the Microsoft Store 
Get-Command -Name python # "$($env:LOCALAPPDATA)\Microsoft\WindowsApps\python.exe"

## Searching for python
winget search python
winget show --id Python.Python.3 

## Default setup is a user install 
winget install --id Python.Python.3    ## User install
winget uninstall --id Python.Python.3 

## System wide setup
winget install --id Python.Python.3 --scope machine   ## Machine install

## The path variable was modified
[Environment]::GetEnvironmentVariable("Path", "Machine") -split ';'
Get-Command -Name python*

## You might want to remove the app execution links
## Mind the gap: the link will still appear in the settings app
Remove-Item -Path "$($env:LOCALAPPDATA)\Microsoft\WindowsApps\python.exe"
Remove-Item -Path "$($env:LOCALAPPDATA)\Microsoft\WindowsApps\python3.exe"