<#
    Setup PowerShell Core 6 on Windows (April 2018)
    https://github.com/PowerShell/PowerShell/releases
    https://docs.microsoft.com/en-us/powershell/scripting/setup/Installing-PowerShell-Core-on-Windows?view=powershell-6
#>

# 6.0.2 
$hash = '48EB15306876ED800A8E510873ED7A60C74858454C66A31E565D28C1EF7EAF2F'
$uri = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.2/PowerShell-6.0.2-win-x64.msi'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   # The usual TLS 1.2 trouble
$file = "$env:TEMP\PowerShell-6.0.2-win-x64.msi"

# Get file
Invoke-WebRequest -useb -uri $uri -OutFile $file

# Setup
if (Compare-Object (Get-FileHash -Path $file).hash $hash) { 'Hash differs!' | Write-Warning } else {
   'Starting setup ..'
   Start-Process -wait -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList '-qn',"-i $file", "-log $file.log" ,'-norestart'
   Get-Content "$file.log" | Set-Clipboard    
   Start-Process -FilePath 'C:\Program Files\PowerShell\6.0.2\pwsh.exe'
}

# Clean up!
# Remove-Item -Path $file 