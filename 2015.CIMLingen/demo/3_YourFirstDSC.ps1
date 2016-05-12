# Remove existing CimSessions
Get-CimSession | Remove-CimSession

# Define variables
$vm = 'linux-host'
$user = 'root'
$password = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText –Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $password)

# TEST endpoint
Test-NetConnection -ComputerName $vm -Port 5986 -InformationLevel Quiet 

# Initiate Session
$sessionOptions = New-CimSessionOption -UseSsl:1 -SkipCACheck:1 -SkipCNCheck:1 -SkipRevocationCheck:1 
$session = New-CimSession -Credential $cred `
  -ComputerName $vm -Port 5986 -Authentication Basic -SessionOption $sessionOptions

# Verify Session
Get-CimClass -Namespace root/omi -CimSession $session -ClassName OMI_Identify # | Select-Object -ExpandProperty CimClassProperties

# Any existing DscConfig?
Get-DscConfiguration -CimSession $session

# DSC test configuration
Configuration MyFirstLinuxDSC 
{
   Import-DSCResource -Module nx
   Node "$vm"{    
        nxFile myTestFile
        {
            Ensure = "Present" 
            Type = "File"
            DestinationPath = "/var/tmp/helloworld_dsc.txt"   
            Mode = "774"
            Owner = "root"
            Group = "root"
            Contents="Hello World! `n"
        }
    }
}
 
MyFirstLinuxDSC -OutputPath 'c:\LinuxDSC'

Start-DscConfiguration -CimSession $session -Path 'C:\LinuxDSC' -Verbose -Wait

#  @LINUXHOST: Check Configuration
# /opt/microsoft/dsc/Scripts/GetConfiguration.py
# cat /opt/omi/var/log/dsc.log

# This should work fine
Get-DscConfiguration -CimSession $session
Test-DscConfiguration -CimSession $session

# Local Machine // Testing
Get-CimInstance -Namespace root/cimv2 -ClassName Win32_service 
Get-CimClass -Namespace root/cimv2
Get-CimClasS -Namespace root/StandardCimv2 

# Remote Machine // :-( 
Get-CimInstance -Namespace root/omi -ClassName OMI_Identify -CimSession $session 
# Get-CimClass -Namespace root/omi -CimSession $session
# Get-CimClass -Namespace root/cimv2 -CimSession $session
# Get-CimClass -Namespace root/StandardCimv2 -CimSession $session