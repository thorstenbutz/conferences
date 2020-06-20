#######################################################################################
# The ThreadJob module
# Import-Module -Name 'C:\Program Files\PowerShell\7\Modules\ThreadJob\ThreadJob.psd1' 
#######################################################################################

Get-Job | Remove-Job
$PSVersionTable 

# A: Standard demo 
# from https://docs.microsoft.com/en-us/powershell/module/threadjob/start-threadjob)
Measure-Command {1..5 | % {Start-Job {Start-Sleep 1}} | Wait-Job} | Select-Object TotalSeconds
Measure-Command {1..5 | % {Start-ThreadJob {Start-Sleep 1}} | Wait-Job} | Select-Object TotalSeconds


# B: Avoiding Measure-Command
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    1..5 | % {Start-Job {Start-Sleep 1}} | Wait-Job
'{0:N2} sec' -f $stopwatch.Elapsed.totalseconds


$stopwatch.Restart()
    1..5 | %  { Start-ThreadJob {Start-Sleep 1}} | Wait-Job
'{0:N2} sec' -f $stopwatch.Elapsed.totalseconds


# C 
Measure-Command -Expression { 
    
    Start-Job -ScriptBlock { ping -n 2 sea-dc1 } | Wait-Job
    Start-Job -ScriptBlock { ping -n 2 sea-sv1 } | Wait-Job
    Start-Job -ScriptBlock { ping -n 2 sea-cl1 } | Wait-Job

} | Select-Object -Property TotalSeconds


# D
Measure-Command -Expression { 

    Start-ThreadJob -ScriptBlock { ping -n 2 sea-dc1 } | Wait-Job
    Start-ThreadJob -ScriptBlock { ping -n 2 sea-sv1 } | Wait-Job
    Start-ThreadJob -ScriptBlock { ping -n 2 sea-cl1 } | Wait-Job

} | Select-Object -Property TotalSeconds


# E
Measure-Command -Expression { 

    'sea-dc1','sea-sv1','sea-cl1'  | ForEach-Object -Process {
        Start-ThreadJob -ScriptBlock { ping -n 2 $_ } | Wait-Job
    }

} | Select-Object -Property TotalSeconds


# F
Measure-Command -Expression { 

    'sea-dc1','sea-sv1','sea-cl1'  | ForEach-Object -Parallel {
        ping -n 2 $_ 
    }

} | Select-Object -Property TotalSeconds
