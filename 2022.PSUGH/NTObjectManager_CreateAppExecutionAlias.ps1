#############################################################################
## The NTObjectManager module (by James Forshaw, Google)
## https://www.powershellgallery.com/packages/NtObjectManager/1.1.33
## https://github.com/googleprojectzero/sandbox-attacksurface-analysis-tools
## James Forshaw: Overview of Windows Execution Aliases
## https://www.tiraniddo.dev/2019/09/
#############################################################################

## Get the module 
Install-PackageProvider -Name nuget -force 
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Find-Module -Name 'NTObjectManager'  | Install-Module -Force # -Scope CurrentUser 

$params = @{
    Path        = "$($env:localappdata)\Microsoft\WindowsApps\aicli.exe"
    PackageName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
    EntryPoint  = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget'
    Target      = "$((Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation)\AppInstallerCLI.exe"
    AppType     = 'Desktop'
    Version     = 3
}
Set-ExecutionAlias @params