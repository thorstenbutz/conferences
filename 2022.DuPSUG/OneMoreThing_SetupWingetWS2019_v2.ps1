##########################################
## Install AppInstaller/WinGet on WS 2019
##########################################

## Install prerequisites

'C:\depot\Microsoft.DesktopAppInstaller_2022.127.2322.0_neutral_~_8wekyb3d8bbwe.msixbundle',
'C:\depot\Microsoft.UI.Xaml.2.7_7.2203.17001.0_x64__8wekyb3d8bbwe.appx',
'C:\depot\Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe.appx' | Add-AppxPackage


## Get MSIX bundle from Github
$baseUri = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

foreach ($uri in (Invoke-RestMethod -uri $baseUri).assets.browser_download_url ) {
    $uri | Write-Host -ForegroundColor Yellow
    Invoke-RestMethod -UseBasicParsing -Uri $uri -OutFile $uri.Split('/')[-1]
}

## Install 
$msix = Get-ChildItem -Filter 'Microsoft.DesktopAppInstaller*.msixbundle'
$license = Get-ChildItem -Filter '*License1.xml'

Add-AppxPackage -Path $msix
Add-AppProvisionedPackage -Online -PackagePath $msix -LicensePath $license

## Test 
Get-Command -Name winget
Get-ChildItem -Path "$($env:localappdata)\Microsoft\WindowsApps" -Recurse -file -Filter winget.exe -ErrorAction SilentlyContinue -Force
Get-ChildItem -Path 'C:\Program Files\WindowsApps' -Recurse -file -Filter winget.exe -ErrorAction SilentlyContinue -Force

$package = Get-AppxPackage -Name Microsoft.DesktopAppInstaller
Invoke-CommandInDesktopPackage -PackageFamilyName $package.PackageFamilyName  -Command 'cmd' -AppId $package.Name

## Create reparse point
$NTObjectManagerModule = Get-Module -ListAvailable -Name 'NTObjectManager'
if ($NTObjectManagerModule) { 'Found NTObjectManager module v' + $NTObjectManagerModule.Version.ToString() } else {
    Install-Module -Name 'NTObjectManager' -Force -scope CurrentUser
} 

$params = @{
    Path        = 'c:\windows\system32\winget.exe' 
    PackageName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe"
    EntryPoint  = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget"
    Target      = "$((Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation)\WinGet.exe"
    AppType     = 'Desktop'
    Version     = 3
}
Set-ExecutionAlias @params

## Fix encoding issues in PowerShell ISE
whoami ; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

## Use WinGet
winget --info 
winget search powershell 
winget install --id Microsoft.PowerShell --source winget