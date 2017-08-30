## Create  a simple NANO server image

#region Create NANO

    # Path to extracted Windows Server 2016 ISO image
    $mediapath = 'C:\demo\ws2016\'

    # Load module: 
    Import-Module "$mediapath\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psm1"             
    Get-Command -Module NanoServerImageGenerator # Check if cmdlet was loaded

    $password = ConvertTo-SecureString -AsPlainText -Force -String 'Pa$$w0rd'

    # Create the Nano image (EDITION: Standard or Datacenter)
    New-NanoServerImage `    -MediaPath $mediapath `    -Edition 'Datacenter' `    -DeploymentType Guest `
    -MaxSize 100GB `
    -TargetPath 'c:\demo\nano2.vhdx' `    -AdministratorPassword $password `    -DomainBlobPath C:\demo\nano2.djoin `    -Package 'Microsoft-NanoServer-DNS-Package' `    -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"') 

    # Optional:
    # -ComputerName 'nano2'
    # -DomainName contoso.com 
    # -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"') 
    # -Storage -Compute -Clustering -Containers -EnableRemoteManagementPort -Defender 

#endregion

#region Setup VM

    $vmname = 'nano2'
    $vhdx = 'c:\demo\nano2.vhdx' 

    New-VM -Name $vmname -MemoryStartupBytes 512MB -Generation 2 -VHDPath $vhdx -SwitchName 'HV_Internal1'
    Set-VM -Name $vmname -ProcessorCount 4
    # Add-VMDvdDrive -VMName $vmname -Path <path to iso file>

    Start-VM -VMName $vmname   

#endregion