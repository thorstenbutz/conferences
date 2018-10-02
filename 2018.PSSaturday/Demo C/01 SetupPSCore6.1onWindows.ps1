####################################################################################################
# Setup PowerShell Core 6 on Windows (September 2018)
# https://github.com/PowerShell/PowerShell/releases
# https://docs.microsoft.com/en-us/powershell/scripting/setup/Installing-PowerShell-Core-on-Windows
####################################################################################################

# 6.1
$hash = 'E67A1460C3D24C52B1DE30DAECBCE7ED7BAAC62DCEF8A862D2FCADC31A9B4239'
$uri = 'https://github.com/PowerShell/PowerShell/releases/download/v6.1.0/PowerShell-6.1.0-win-x64.msi'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   # The usual TLS 1.2 trouble
$file = "$env:TEMP\PowerShell-6.1.0-win-x64.msi"

# Get file
Invoke-WebRequest -useb -uri $uri -OutFile $file

# Setup
if (Compare-Object (Get-FileHash -Path $file).hash $hash) { 'Hash differs!' | Write-Warning } else {
   'Starting setup ..'
   Start-Process -wait -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList '-qn',"-i $file", "-log $file.log" ,'-norestart'
   #siexec /i .\PowerShell-6.0.0-win-x64.msi /q
   Get-Content "$file.log" | Set-Clipboard    
   Start-Process -FilePath 'C:\Program Files\PowerShell\6\pwsh.exe' -ArgumentList '-WorkingDirectory c:\'   
}

# Clean up!
# Remove-Item -Path $file 