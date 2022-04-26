###########################################################
## Invoke-CommandInDesktopPackage 
## Runs commands in the context of a specified app package
###########################################################

## Example A
$appx = Get-AppxPackage -Name *HaukeGtze.NotepadEditor*
Invoke-CommandInDesktopPackage -PackageFamilyName $appx.PackageFamilyName -Command 'notepad++.exe'

## Example B
$appx = Get-AppxPackage -Name *DesktopAppInstaller*
Invoke-CommandInDesktopPackage -PackageFamilyName $appx.PackageFamilyName -Command 'cmd.exe'

## Try this:
## cd "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.16.13405.0_x64__8wekyb3d8bbwe\"
## AppInstallerCLI.exe --info