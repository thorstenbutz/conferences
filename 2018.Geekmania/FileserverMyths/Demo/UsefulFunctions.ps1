function Test-Admin
{
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function prompt { 
    $principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){$color = 'red'} else {$color = 'green'}
    write-host -f $color -no '[' 
    write-host -f white -no $Env:username
    write-host -f $color -no '] '
    "$pwd> "
}

function prompt2 { 
    $principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')){$color = 'red'} else {$color = 'green'}
    if ($PSVersionTable.PSEdition -eq 'Core') { $a  = '(' ; $b = ')' } else {  $a  = '[' ; $b = ']'} 
    write-host -f $color -no $a 
    write-host -f white -no $Env:username 
    write-host -f $color -no "$b "
    "$pwd> "
} 
 