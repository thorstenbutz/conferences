####################################
# The "WindowsCompatibility" module
# (aka rModule)
####################################

Get-Command -Module ActiveDirectory

Find-Module -Name WindowsCompatibility # v0.0.1 September 2018
Install-Module -Name WindowsCompatibility -force -scope AllUsers

Import-WinModule -Name ActiveDirectory # if RSAT locally installed
Import-WinModule -Name ActiveDirectory -ComputerName sea-dc1 # -Credential $cred

Get-ADDomain