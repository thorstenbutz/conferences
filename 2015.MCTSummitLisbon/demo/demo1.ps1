#region COMMANDS

Get-Command -Verb get | Measure-Object | Select-Object -ExpandProperty Count
Get-Command gcm
Get-Command help
Get-Command date

[System.DateTime]::Now
Get-Date 
(Get-Date).gettype()
date   

#endregion

#region THE DNA OF POWERSHELL: BASIC DATA TYPES

# Integer
1 -is [int]

# String
'Donald' -is [string]
"My favourite cartoon is $name." -is [string]

# Boolean
$false -is [bool]

# Multiple items
'Huey', 'Dewey', 'Louie' -is [array]

$ducks = Import-Csv -Path .\ducktown.csv
$ducks | Select-Object -Property givenName, Computername
$ducks -is [array]
$ducks -is [object]
$ducks[0].gettype()

#endregion

#region THE DNA OF POWERSHELL: PIPELING 

# A pipeline of strings:  "Implicit" pipelining 
'Huey', 'Dewey', 'Louie' | Write-Host -ForegroundColor Yellow 

# "Explicit" pipeling: The array syntax
'Huey', 'Dewey', 'Louie' | ForEach-Object { "$_ is a nephew of Donald." } 
'Huey', 'Dewey', 'Louie' | ForEach-Object { "$_ is a nephew of Donald." }
 
# A pipeline of objects
$ducks | Select-Object -Property Computername
$ducks | Select-Object -ExpandProperty Computername
$ducks | ForEach-Object { $_.Computername }

# c) Parameter binding
'dt-cl1' | Test-Connection -Quiet # ERROR
$ducks | Test-Connection -Quiet

Get-Help -Name Test-Connection -Parameter computername

#endregion