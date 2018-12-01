################################
# LocalAccountTokenFilterPolicy
################################

#region SMB ACCESS
    $computername = 'sea-cl4'
    Test-Connection -ComputerName $computername -Count 2
  
    Test-Path -path "\\$computername\c$"
    Test-Path -path "\\$computername\depot"

    # Verify if LocalAccountTokenFilterPolicy is set
    Get-ItemProperty –Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' –Name 'LocalAccountTokenFilterPolicy'

#endregion

#region WINDOWS CLIENT: ENABLE PSREMOTING

    Enable-PSRemoting -Force 
    Test-WSMan -ComputerName $computername 

    # BEFORE YOUR PROCEED:
    # LOGON TO THE REMOTE COMPUTER AND ENABLE PSREMOTING

    # TRY AGAIN (WITH AND WITHOUT CREDENTIALS)
    Test-WSMan -ComputerName $computername -Authentication Default

    Get-Item WSMan:\localhost\Client\TrustedHosts
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $computername -Force

    Get-ItemProperty –Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' –Name 'LocalAccountTokenFilterPolicy'

    Invoke-Command -ComputerName $computername -ScriptBlock { 
        $env:COMPUTERNAME 
        New-Item -Path "c:\$((Get-Date).Ticks).txt" # REQUIRES FULL ADMIN PRIVS
    }

#endregion

#region WINDOWS SERVER: CHECK REMOTE ADMIN RIGTHS AGAIN
    
    $computername = 'sea-sv3' # Server with a GUI !

    #$password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText -Force
    # $cred = [pscredential]::new('administrator',$password)
    
    Test-Path -path "\\$computername\c$"
    Test-Path -path "\\$computername\depot"   # Try -credentials $cred
    
    Get-Item WSMan:\localhost\Client\TrustedHosts
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $computername -Force 

    # Try localadmin AND Administrator
    Test-WSMan -ComputerName $computername -Authentication Default -Credential $cred

    # Granting "full admin token" rights to protected admins 
    Invoke-Command -ComputerName $computername -Credential $cred -ScriptBlock { 
        $env:COMPUTERNAME
        #(Get-ItemProperty –Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' –Name 'LocalAccountTokenFilterPolicy').LocalAccountTokenFilterPolicy
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\microsoft\Windows\CurrentVersion\Policies\System\' -Name 'LocalAccountTokenFilterPolicy' -Value 0
        # Remove-ItemProperty -Path 'HKLM:\SOFTWARE\microsoft\Windows\CurrentVersion\Policies\System\' -Name 'LocalAccountTokenFilterPolicy'
        (Get-ItemProperty –Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' –Name 'LocalAccountTokenFilterPolicy').LocalAccountTokenFilterPolicy        
    }

    Test-WSMan -ComputerName $computername -Authentication Default -Credential $cred

#endregion

#region UAC

    (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').FilterAdministratorToken 
    # Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'FilterAdministratorToken' -Value 1
    # Restart-Computer

#endregion