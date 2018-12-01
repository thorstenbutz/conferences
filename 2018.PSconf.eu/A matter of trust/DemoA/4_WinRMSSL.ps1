<#
    CODE SIGNING LAB // v180219    
    makecert.exe: 
    https://msdn.microsoft.com/en-us/library/windows/desktop/aa386968%28v=vs.85%29.aspx 
#>

#region CHECK CURRENT CONFIG

    $computername = 'sea-cl3'
    Test-WSMan -ComputerName $computername -Authentication Default
    winrm.cmd enumerate winrm/config/listener

#endregion

<#
    SSL requirements for PoSh remoting
    - Must have a certificate (Server Authentication)
    - Installed in Local Computer/Personal (My)
    - Must have private key
    - Obtain through internal PKI or Public CA (avoid self signed)
#>

Get-ChildItem -path 'Cert:\LocalMachine\My' | 
  Where-Object { $_.hasprivatekey -and $_.EnhancedKeyUsageList.FriendlyName -contains 'Server Authentication'} | 
    Format-Table Thumbprint,EnhancedKeyUsageList,DNSNameList, Subject,Issuer 
 
# Variables 
$MyName = 'PSconfEU'
$ServerNames = 'sea-cl3','sea-cl4'
$makecert = 'C:\depot\makecert\makecert.exe' 

# Create Root CA
&$makecert -pe -n "CN=$MyName-RootCA" -ss root -sr LocalMachine -sky signature -r "$MyName-RootCA.cer" 

# Create TLSCerts
$ServerNames | ForEach-Object {
    &$makecert -pe -n "CN=$_" -ss my -sr LocalMachine -sky exchange `
      -eku 1.3.6.1.5.5.7.3.1 -in "$MyName-RootCA" -is root -ir LocalMachine `
      -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 "$_-TLSCert.cer" 
}

# Export TLSCerts
$myCerts = Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object { $_.Issuer -like "CN=$MyName-RootCA" } 
$myCerts | Select-Object Subject, Issuer, EnhancedKeyUsageList, Thumbprint

$myTLSCerts =  Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object { $_.Issuer -like "CN=$MyName-RootCA" -and $_.EnhancedKeyUsageList -like '*1.3.6.1.5.5.7.3.1*' } 
$myTLSCerts | Select-Object Subject, Issuer, EnhancedKeyUsageList, Thumbprint

$myTLSCerts | ForEach-Object {
    $filename = ($_.Subject).replace('CN=','') + '-TLSCert.pfx'  
    Export-PfxCertificate -cert $_ -FilePath $filename -Password (ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force) -Force
}

# New TLS-Listener
$myTLSCerts[0]
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $myTLSCerts[0].Thumbprint -Force
Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 5986

## Variant A
Get-NetFirewallRule | Where-Object { $_.displayName -like "*Windows Remote Management*" } | Select-Object Name, DisplayName, Enabled, Description
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "WINRM-HTTPS-In-TCP (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP -Description 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]'

## Variant B:
# Get-NetFirewallRule -Name 'WINRM-HTTP-In-TCP' | Copy-NetFirewallRule -NewName 'WINRM-HTTPS-In-TCP'
# Get-NetFirewallRule -Name 'WINRM-HTTPS-In-TCP' | Set-NetFirewallRule -LocalPort 5986 -NewDisplayName 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]'


Get-NetFirewallRule -DisplayName 'Windows Remote Management (HTTP-IN)*' | 
  Format-Table Name, Displayname, Enabled, Profile, Group, 
    @{l='LocalAddress'; e={($_ | Get-NetFirewallAddressFilter).LocalAddress }},
    @{l='RemoteAddress'; e={($_ | Get-NetFirewallAddressFilter).RemoteAddress }}

# Enable access from anywhere
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
  # or
# Set-NetFirewallRule –Name 'WINRM-HTTP-In-TCP-PUBLIC' -RemoteAddress 'Any'

#region THE REMOTE COMPUTER
$remotecomputer = 'sea-cl4' 
$file1 = 'C:\depot\PSconfEU-RootCA.cer'
$file2 = "C:\depot\$remotecomputer-TLSCert.pfx"
test-path $file1,$file2

# We still need this, we have not yet finished SSL configuration
Get-Item -Path WSMan:\localhost\Client\TrustedHosts
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $remotecomputer -Force

# New session object
$session = New-PSSession -ComputerName $remotecomputer

Copy-Item -Path $file1, $file2 -Destination "\\$remotecomputer\depot\"

# Copy-Item -Path $file1,$file2 -ToSession $session -Destination 'C:\depot'

Invoke-Command -Session $session -ArgumentList $file1,$file2 -ScriptBlock {
    param ($file1, $file2)
    #Import-Certificate -FilePath $file1 -CertStoreLocation Cert:\LocalMachine\Root 
    #Import-PfxCertificate -FilePath $file2 -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force)
    
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My -Recurse | Where-Object { $_.Subject -like 'CN=' + $env:computername } 
    $cert.Thumbprint
    New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
    Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 5986
    
    #New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "WINRM-HTTPS-In-TCP (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP -Description 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]'
}

Test-NetConnection -ComputerName $remotecomputer -Port 5986

Get-Item -Path WSMan:\localhost\Client\TrustedHosts
Clear-Item -Path WSMan:\localhost\Client\TrustedHosts
Test-WSMan -ComputerName $remotecomputer -UseSSL -Authentication Default
Invoke-Command -ComputerName $remotecomputer -UseSSL -ScriptBlock { hostname }
