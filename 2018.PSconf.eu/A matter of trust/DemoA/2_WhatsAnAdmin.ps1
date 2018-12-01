#####################
# Whats an "admin" ? 
#####################

#region TRIVIA

    whoami.exe /user
    whoami.exe /groups | Select-String -SimpleMatch 'Administrators '
    whoami.exe /priv

#endregion

#region Functions

    function Test-Admin
    {
        $principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    Test-Admin

    function prompt { 
        $principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){$color = 'red'} else {$color = 'green'}
        write-host -f $color -no '[' 
        write-host -f white -no $Env:username
        write-host -f $color -no '] '
        "$pwd> "
    } 

# Lets put that in a profile
psedit $Profile.AllUsersAllHosts

#endregion