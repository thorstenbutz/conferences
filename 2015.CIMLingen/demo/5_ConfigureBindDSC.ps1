Get-CimSession 
Test-DscConfiguration -CimSession $session

$vm
$OFS = [Environment]::NewLine # Fix new line problem 
$db_contoso_com = Get-Content 'C:\demo_C\db.contoso.com'
$named_conf_local = Get-Content 'C:\demo_C\named.conf.local'

Configuration BindTest1
{
   Import-DSCResource -Module nx

   Node $vm {    
   
        nxPackage bind
        {
            Name = 'bind9'
            Ensure = "Present"
            PackageManager = "apt"                        
        }

        nxFile named.conf.local
        {
            Ensure = "Present"
            Type = "File"            
            Contents = "$named_conf_local"
            DestinationPath = "/etc/bind/named.conf.local"
            Group = "bind"
            Mode = "644"            
        }

        nxFile db.contoso.com
        {
            Ensure = "Present"
            Type = "File"            
            Contents = "$db_contoso_com"
            DestinationPath = "/var/lib/bind/db.contoso.com"
            Group = "bind"
            Mode = "664"            
        }

        nxScript bind_reload
        {
            GetScript = @"
#!/bin/bash
service bind9 status
"@

            SetScript = @"
#!/bin/bash
service bind9 reload
"@

            TestScript = @"
#!/bin/bash
service bind9 reload
"@
            DependsOn = "[nxPackage]bind","[nxFile]named.conf.local","[nxFile]db.contoso.com"
        }
    }
}

BindTest1 -OutputPath 'c:\LinuxDSC'

Start-DscConfiguration -CimSession $session -Path 'C:\LinuxDSC' -Verbose -Wait

# @LINUXHOST: check confgig
# dig sea-test3.contoso.com @localhost +short

Resolve-DnsName -Name sea-test3.contoso.com -Server sea-www5 -DnsOnly