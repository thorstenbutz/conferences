###########################################
## Howto call a function in a remote scope
###########################################

$remoteComputer = $env:COMPUTERNAME
$cred = Get-Credential

## A
function foo { 
    param (
        [string] $bar    
    )
    "My value: $bar!"
}

Invoke-Command -ComputerName $remoteComputer -Credential $cred -ScriptBlock ${function:foo} -ArgumentList 'John'


## B
$code = {
    function foo { 
        param (
            [switch] $bar        
        )
        "My value: $bar!"
    }
    foo -bar
}

# Local
$code.invoke()

# Remote
Invoke-Command -ComputerName $remoteComputer  -Credential $cred -ScriptBlock $code