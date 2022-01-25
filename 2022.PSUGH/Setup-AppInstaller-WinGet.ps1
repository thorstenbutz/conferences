################################################################################
# WinGET
# aka "Windows Package Manager" 
# Included in "Microsoft.DesktopAppInstaller", minimum 1.11.11451.0 
# Depends on "Microsoft.VCLibs.140.00.UWPDesktop", minimum version 14.0.29231.0
################################################################################

## Get MSIX bundle from Github
$baseUri = 'https://api.github.com/repos/microsoft/winget-cli/releases'
$uri = (Invoke-RestMethod -uri $baseUri).assets.browser_download_url  | Sort-Object -Descending | Where-Object -FilterScript { $_ -like '*msixbundle' } | Select-Object -First 1
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $uri.Split('/')[-1]

## Install
Write-Host -ForegroundColor Yellow 'WinGet depends on "Microsoft.VCLibs.140.00.UWPDesktop", minimum version 14.0.29231.0'
$vclibs = 'C:\depot\tools\VCLibs\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
if (Test-Path -Path $vclibs) {
    Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath $vclibs
    # Add-AppPackage -path $vclibs
}

## System wide install, requires admin privileges 
Add-AppxProvisionedPackage -SkipLicense -Online -PackagePath $uri.Split('/')[-1]
# Get-AppxProvisionedPackage -Online | Where-Object -FilterScript { $_.DisplayName -like 'Microsoft.DesktopAppInstaller' } | Remove-AppxProvisionedPackage -Online -AllUsers

## User install
# Add-AppPackage -Path $uri.Split('/')[-1] 

## Fix encoding issues 
whoami ; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

## Find Winget.exe
Get-Command -Name winget
Test-Path -Path "$home\AppData\Local\Microsoft\WindowsApps\winget.exe"

## Use WinGET
winget search 
winget search | Select-String -SimpleMatch Opera
winget search > winget-applications.txt 
notepad winget-applications.txt 

winget search powershell
winget search terminal
winget search vscode 
winget search powertoy

winget install --exact Microsoft.PowerShell
winget install --exact Microsoft.WindowsTerminal # start wt 
winget install --exact Microsoft.OfficeDeploymentTool 
winget install --exact Microsoft.PowerToys 

winget install --exact Opera.Opera
winget install --exact VivaldiTechnologies.Vivaldi 
winget install --exact BraveSoftware.BraveBrowser  
winget install --exact CPUID.CPU-Z  
winget install --exact Greenshot.Greenshot
winget install --exact Microsoft.XMLNotepad  
winget install --exact Notepad++.Notepad++

## Setup Microsoft Office with the OfficeDeploymentTool
& 'C:\Program Files\OfficeDeploymentTool\setup.exe' /configure 'C:\Program Files\OfficeDeploymentTool\configuration-Office2019Enterprise.xml'

## Show applications to be uninstalled
winget uninstall

## Upgrade
winget list --id Microsoft.PowerToys
winget upgrade --id Microsoft.PowerToys

winget list --id Mozilla.Firefox
winget upgrade  --id Mozilla.Firefox
winget upgrade --all

## Uninstall
winget uninstall --exact --silent Notepad++.Notepad++  
winget uninstall --exact --silent Microsoft.PowerShell.Preview 