Get-CimSession 
Test-DscConfiguration -CimSession $session

# @LINUXHOST: Check configuration
# service apache2 status 
# cat /etc/passwd | grep Donald 
# cat /etc/group | grep Ducks

$MyTestUser = "Donald"
$MyTestGroup = "Ducks"
$MyTestService = "apache2"

Configuration YetAnotherDSCTest
{
   Import-DSCResource -Module nx

   Node $vm {    
   
        nxUser myTestUser
        {
            Ensure = 'Present'
            UserName = $MyTestUser
            Password = 'SuperSecret'
            
        }

        nxGroup myTestGroup
        {
            Ensure = 'Present'
            Groupname = $MyTestGroup
            MembersToInclude = $MyTestUser
            DependsOn = '[nxUser]MyTestUser'
        }

        nxService myTestService
        {
            Name = $MyTestService
            State = "Running"
            Enabled = $true
            Controller = "init"
        }
    }
}

YetAnotherDSCTest -OutputPath "c:\LinuxDSC"
Start-DscConfiguration -CimSession $session -Path "C:\LinuxDSC" -Verbose -Wait