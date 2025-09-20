#############################################
## DEMO: Howto run explorer in elevated mode
#############################################

## Load the "Lee Holmes" function
. .\SetTokenPrivilege.ps1

## Remove the blocker from the registry
.\Enable-ExplorerRunAs.ps1  

## Start (another instance of the) explorer with administrative rights
Start-Process -FilePath 'explorer.exe' -ArgumentList 'c:\' -Verb 'RunAs' 
$explorer = Get-Process -Name 'explorer' -IncludeUserName | 
  Sort-Object -Property 'StartTime' | 
  Select-Object -Property 'StartTime','Id','Processname' -Last 1

## Enable privileges
Set-TokenPrivilege -Privilege 'SeBackupPrivilege' -ProcessId $explorer.Id
Set-TokenPrivilege -Privilege 'SeRestorePrivilege' -ProcessId $explorer.Id