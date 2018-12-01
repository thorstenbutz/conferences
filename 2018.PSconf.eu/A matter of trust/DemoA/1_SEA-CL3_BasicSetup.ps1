################################
# LocalAccountTokenFilterPolicy
# Basic Setup: sea-cl3
################################

# CREATE LOCAL ADMIN USER
# New-LocalUser 'localadmin' -Password (ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force) -UserMayNotChangePassword 
# Add-LocalGroupMember -Group 'Administrators' -Member 'localadmin' 
Get-LocalUser -Name 'localadmin'
Get-LocalGroupMember -Name 'Administrators' 

# BASIC SETUP 
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
Test-Path -Path 'c:\depot'  # New-Item -Path 'c:\depot' -ItemType Directory
New-SmbShare -Name 'depot' -Path 'C:\depot' -FullAccess Everyone     # Remove-SmbShare -Name depot -Force

# CREATE PROFILE
New-Item $PROFILE.AllUsersAllHosts
'$host.ui.RawUI.WindowTitle = "PowerShell-" + $PSVersionTable.psversion + " (" + $env:COMPUTERNAME + ")"' >> $PROFILE.AllUsersAllHosts
'$host.PrivateData.ErrorBackgroundColor = "White"' >> $PROFILE.AllUsersAllHosts
'Set-Location c:\' >> $PROFILE.AllUsersAllHosts
'Clear-Host' >> $PROFILE.AllUsersAllHosts
