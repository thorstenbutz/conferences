#region Authentication

    #set-Item WSMan:\localhost\Client\TrustedHosts -Value *
    $username = 'contoso\administrator'
    $password = ConvertTo-SecureString -AsPlainText -Force -String 'Pa$$w0rd'

    $cred = [System.Management.Automation.PSCredential]::new($username,$password)
    $cred = Get-Credential
    
    $computername = 'sea-dc1' # name or IP
    $vmname = 'sea-dc1' # name of the VM for PS direct
    
    Test-WSMan -ComputerName $computername  -Credential $cred -Authentication Default
    
#endregion


#region Create session

    # Create PSSession 

    # A: regular session via network
    # $session = New-PSSession -ComputerName $computername -Credential $cred

    # B: PowerShell direct via VMBus
    $pssession = New-PSSession -VMName $vmname -Credential $cred 
        
#endregion


#region DJOIN

    # Run djoin multiple times
    Invoke-Command -Session $pssession {
       foreach ($computer in 2..3) {
         hostname
          djoin.exe /Provision /Domain contoso.com /Machine "nano$computer" /SaveFile "c:\nano$computer.djoin"
       }
    }
    foreach ($computer in 2..3) {
      Copy-Item -Path "c:\nano$computer.djoin" -Destination "c:\demo\nano$computer.djoin" -FromSession $pssession
    }

    # Clean up!
    Get-PSSession | Remove-PSSession

#endregion