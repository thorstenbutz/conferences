#region TYPE LITERALS, VARIABLE "DECLARATION"

 $a = 1
 $a.GetType()

 $a = '1'
 $a.GetType()

 [int]$b = 1      # type literal
 $b.GetType()

 $b = '1'
 $b.GetType()

 # Beware of 'read-host' !

#endregion

#region COMPARISONOPERATOR vs. STRINGMETHOD 

'Scrooge Duck' -replace 'Scrooge','Dagobert'   | Write-Host -ForegroundColor Yellow
('Scrooge Duck').replace('Scrooge','Dagobert') | Write-Host -ForegroundColor Green

# Case sensitive? 
'Scrooge Duck' -replace 'scrooge','dagobert'   | Write-Host -ForegroundColor Yellow
('Scrooge Duck').replace('scrooge','dagobert') | Write-Host -ForegroundColor Green

# Further
'Scrooge.Duck' -replace '.',''   | Write-Host -ForegroundColor Yellow
('Scrooge.Duck').replace('.','') | Write-Host -ForegroundColor Green

#endregion

#region EXTERNAL COMMANDS

# Group analysis
whoami /groups /fo csv | ConvertFrom-Csv | Where-Object { $_.'Group Name' -like 'contoso*' } 

# Mirroring directories
$src = 'c:\sales\2015'
$dst = 'c:\backup\sales\2015'
robocopy.exe /mir $src $dst 

# Setting access rights
new-item -ItemType directory -Path $src
Remove-Item -Path $src -Recurse -Force
icacls.exe $src /inheritance:r
icacls.exe $src /grant 'Administrators:(OI)(CI)(M)'
icacls.exe $src /grant 'Authenticated Users:(OI)(CI)(RX)'
icacls.exe $src 

# Inventory
systeminfo.exe
systeminfo.exe /fo csv | ConvertFrom-Csv
systeminfo.exe /fo csv | ConvertFrom-Csv | Select-Object -Property 'Host Name', 'OS Version'

# The shortest HW inventory script on earth
$computers = Get-ADComputer -Filter { name -like '*dc*' }
$computers += 'localhost'
$result = @()
$computers | ForEach-Object {
 $result +=  Invoke-Command -ComputerName $_.DNSHostname  -ScriptBlock {
   systeminfo.exe /fo csv | ConvertFrom-Csv
 }
}
$result | Format-Table -AutoSize -Property 'Host Name', 'OS Name', 'OS Version', 'OS Configuration', 'Total Physical Memory'
Send-MailMessage -To 'uhd@contoso.com'  -from 'posh@contoso.com' -Subject 'HW report' -Body ($result | Out-String)

#endregion

#region MR BOOL AND THE EVIL SWITCH

# Custom type/System Enum: true, false, 1, 2
Get-NetFirewallRule -Enabled True

# Boolean: $true, $false, 0 , 1
New-ADUser -Name 'John' -Enabled $true 

# Switch:
try { Get-ADUser -Identity 'John' } catch { New-ADUser -Name 'John' -Enabled $true }

Remove-ADUser -Identity 'John' -Confirm:$false   
Remove-ADUser -Identity 'John' -Confirm:0      


# YET ANTHER EXAMPLE, EVEN MORE CONFUSING

function RunNetworkChecks {
 [CmdletBinding()]  
#[CmdletBinding(PositionalBinding=$false)]   #requires -version 3
  param(
    [switch]$enableWMICheck, 
    [bool]$enableWSManCheck, 
    [ValidateSet('True','False')]
    [string]$enableRDPCheck='False'
  )
    
  "WMI check enabled?   $enableWMICheck"
  "WSMan check enabled? $enableWSManCheck"  
  "RDP check enabled?   $enableRDPCheck" 
  
  # To be continued later  ..
}

RunNetworkChecks
RunNetworkChecks -enableWMICheck:$true -enableWSManCheck:$false -enableRDPCheck:true
RunNetworkChecks -enableWMICheck $true -enableWSManCheck $false -enableRDPCheck true  # SYNTAX ERROR // ADV. FUNCTION
RunNetworkChecks $true $true

#endregion 