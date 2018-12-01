###########################################################
# The 2nd hop: Session Configuration and a custom endpoint
###########################################################

<#  How to convert the Session SDDK string
    $config = Get-PSSessionConfiguration | Select-Object -First 1
    ConvertFrom-SddlString $config.SecurityDescriptorSddl
#>


$password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$cred = [pscredential]::new('contoso\Administrator',$password)

$ServerA = 'sea-sv1'
$ServerB = 'sea-sv2'
   
# 2nd hop: basic test
Invoke-Command -ComputerName 'sea-sv1' -ScriptBlock  {
        $env:COMPUTERNAME | Write-Host -ForegroundColor Yellow           
        Test-Path -Path "\\sea-dc1\c$" 
        Test-WSMan -ComputerName 'sea-sv2' -Authentication Default       
}

# Create SessionConfiguration 
Invoke-Command -ComputerName 'sea-sv1' -ScriptBlock {    
    $env:COMPUTERNAME
    Get-PSSessionConfiguration -Name PSConf* | Unregister-PSSessionConfiguration -Force
    # return    
    Register-PSSessionConfiguration -Name PSConf -RunAsCredential $using:cred 
    Restart-Service -Name WinRM
}

Invoke-Command -ComputerName  'sea-sv1' -ConfigurationName PSconf -ScriptBlock {
    $env:COMPUTERNAME
    Test-Path -Path "\\sea-dc1\c$"  
    Test-WSMan -ComputerName 'sea-sv2' -Authentication Default
}

