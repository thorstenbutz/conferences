#####################
# Implicit remoting
#####################

# Mind the group membership of the logged on user
whoami /user 
whoami /groups /fo csv | ConvertFrom-Csv | Select-Object -Property 'Group Name'

# To create objects in AD we need a more priviliged account
$username = 'administrator@contoso.com'
$password = ConvertTo-SecureString -AsPlainText -Force -String 'Pa$$w0rd'
$cred = [System.Management.Automation.PSCredential]::new($username,$password)

# Create remote session: IMPLICIT remoting
$pssession = New-PSSession -ComputerName sea-dc1 -Credential $cred
$proxyCmdlets = Import-PSSession -Session $pssession -Module ActiveDirectory # -Prefix Remote

# Test remote acccess 
New-ADOrganizationalUnit -Name 'Research'
$ou = (Get-ADOrganizationalUnit -Filter { name -eq 'Research' }).DistinguishedName
$ou | Write-Host -ForegroundColor Yellow
Set-ADOrganizationalUnit -Identity $ou -ProtectedFromAccidentalDeletion $false 
Remove-ADOrganizationalUnit -Confirm:$false -Identity $ou 

# Clean up
Remove-Module -Name $proxyCmdlets
Get-PSSession | Remove-PSSession 