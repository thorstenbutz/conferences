<#
    Setup Win32-OpenSSH on Windows (April 2018)
    http://github.com/PowerShell/Win32-OpenSSH/releases    
    https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH 
#>

# v7.6.1.0p1-Beta 
$hash = 'A8BF470DD399B0A513268D1A8E33A444CEFB1A1DE539CAB42A952D2EDA7B17D6'
$uri = 'http://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.6.1.0p1-Beta/OpenSSH-Win64.zip'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   # TLS 1.2 trouble
$file = "$env:TEMP\OpenSSH-Win64.zip"

# Get file
Invoke-WebRequest -useb -uri $uri -OutFile $file

# Setup
if (Compare-Object (Get-FileHash -Path $file).hash $hash) { 'Hash differs!' | Write-Warning } else {
   
    'A: Expanding download files'      
    Expand-Archive -Path $file
    New-Item 'C:\Program Files\OpenSSH\' -ItemType Directory
    Move-Item '.\OpenSSH-Win64\OpenSSH-Win64\*' 'C:\Program Files\OpenSSH\' 
    Remove-Item '.\OpenSSH-Win64' -Recurse

    'B: Run setup'
    & 'C:\Program Files\OpenSSH\install-sshd.ps1'    
    netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP localport=22
    Get-Service -Name ssh* | Start-Service
    Set-Service sshd -StartupType Automatic
    Set-Service ssh-agent -StartupType Automatic
    
    $path = (Get-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment’ -Name PATH).Path
    if ($Path[-1] -eq ';')  { $Path += 'C:\Program Files\OpenSSH' } else { $Path += ';C:\Program Files\OpenSSH' }
	'New path: ' 
    $path
    Set-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment’ -Name PATH -Value $path

    'C: Check environment'
    Get-Service -Name ssh* | Select-Object -Property Status, Starttype, Name, Displayname
    Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 22 -InformationLevel Quiet

    'D: Set default shell'
    # Built-in PowerShell
    New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force
    New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShellCommandOption' -Value '/c' -PropertyType String -Force
    
    # PowerShell Core
    # Remove-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell'
    # Remove-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShellCommandOption'
    # New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -Value 'C:\Program Files\PowerShell\6.0.2\pwsh.exe' -PropertyType String -Force
    # New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShellCommandOption' -Value '/c' -PropertyType String -Force
    
}

# Clean up!
# Remove-Item -Path .\OpenSSH-Win64 -Recurse
# Remove-Item -Path $file

# Uninstall:
# & 'C:\Program Files\OpenSSH\uninstall-sshd.ps1'
