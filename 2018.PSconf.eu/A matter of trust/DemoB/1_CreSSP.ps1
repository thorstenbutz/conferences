#############
# The 2nd hop
#############

$password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
$cred = [pscredential]::new('contoso\Administrator',$password)

$ServerB = 'sea-dc1'
$ServerA = 'sea-sv1'
$ServerC = 'sea-sv1'

Test-WSMan -ComputerName $ServerA -Credential $cred -Authentication Kerberos
Test-WSMan -ComputerName $ServerB -Credential $cred -Authentication Kerberos
Test-WSMan -ComputerName $ServerC -Credential $cred -Authentication Kerberos

#region Example A: Whats the 2nd hop? 
    
    # 1st hop
    Invoke-Command -ComputerName $serverA -Authentication Kerberos -ScriptBlock  { 
        $env:COMPUTERNAME | Write-Host -ForegroundColor Yellow           
        
        # 2nd hop
        Invoke-Command -ComputerName $using:ServerB -Authentication Kerberos -ScriptBlock { 
            $env:COMPUTERNAME | Write-Host -ForegroundColor Green
        }
    }
#endregion


#region Example B: Provide Credentials explicitly via $using

    # 1st hop
    Invoke-Command -ComputerName $serverA -Authentication Kerberos -Credential $cred -ScriptBlock  { 
        $env:COMPUTERNAME | Write-Host -ForegroundColor Yellow                   

        # 2nd hop
        Invoke-Command -ComputerName $using:ServerB -Authentication Kerberos -Credential $using:cred -ScriptBlock { 
            $env:COMPUTERNAME | Write-Host -ForegroundColor Green
        }
    }

#endregion

#region Example C: Provide Credentials explicitly via arguments

    # 1st hop
    Invoke-Command -ComputerName $serverA -Authentication Kerberos -ArgumentList $cred,$serverA,$ServerB,$ServerC -ScriptBlock  { 
        param ($cred,$serverA,$ServerB,$ServerC)               
        $env:COMPUTERNAME | Write-Host -ForegroundColor Yellow           
        
        # 2nd hop
        Invoke-Command -ComputerName $serverB -Authentication Kerberos -Credential $cred -ArgumentList $cred,$serverA,$ServerB,$ServerC -ScriptBlock { 
            param ($cred,$serverA,$ServerB,$ServerC)
            $env:COMPUTERNAME | Write-Host -ForegroundColor Green            
            
            # 3rd hop            
            Test-WSMan -Authentication Kerberos -ComputerName $serverC -Credential $cred

        }
    }

#endregion


#region CredSSP
    
    # @CLIENT
    Get-WSManCredSSP
  
    Enable-WSManCredSSP -Role Client -DelegateComputer $ServerA

    Get-ChildItem -Path WSMan:\localhost\Service\Auth | Where-Object { $_.Name -eq 'CredSSP' }
    Get-ChildItem -Path WSMan:\localhost\Client\Auth  | Where-Object { $_.Name -eq 'CredSSP' }
    Get-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials

    # @SERVER
    Invoke-Command -ComputerName $ServerA -ScriptBlock { 
        #Enable-WSManCredSSP -Role Server -Force
        #Get-WSManCredSSP
        Get-ChildItem -Path WSMan:\localhost\Service\Auth | Where-Object { $_.Name -eq 'CredSSP' }
        Get-ChildItem -Path WSMan:\localhost\Client\Auth  | Where-Object { $_.Name -eq 'CredSSP' } 
    }

    # TEST    
    Test-WSMan -ComputerName $ServerA -Authentication Credssp -Credential $cred
        
    # 1st hop
    Invoke-Command -ComputerName $serverA -Authentication Credssp -Credential $cred -ScriptBlock  { 
        $env:COMPUTERNAME | Write-Host -ForegroundColor Yellow           
        Test-Path -Path "\\sea-dc1\c$"

        # 2nd hop
        Invoke-Command -ComputerName $using:ServerB  { 
            $env:COMPUTERNAME | Write-Host -ForegroundColor Green
            Test-Path -Path "\\sea-dc1\c$"
        }
    }
    
    Invoke-Command -ComputerName $serverA -Authentication Credssp -Credential $cred.UserName -ScriptBlock  {   $env:COMPUTERNAME | Write-Host -ForegroundColor Green }
#    Enable-WSManCredSSP
#endregion



Enter-PSSession -ComputerName sea-dc1 -Authentication Kerberos
Enter-PSSession -ComputerName sea-sv1 -Authentication Kerberos
Test-Path -Path \\sea-sv1\c$ 
Test-Path -Path \\sea-dc1\c$ 
Invoke-Command -ComputerName sea-sv1 -ScriptBlock { $env:COMPUTERNAME } -Authentication Kerberos
exit
Get-WSManCredSSP