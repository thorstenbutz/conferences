#########################################
# Performance testing: Grouping, Sorting 
#########################################

$filename = $env:TEMP + (Get-Date).Ticks
if (Test-Path -Path $filename) { Read-Host -Prompt 'File exists. Continue? '}

# A: Finding files
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$files = Get-ChildItem -Path C:\Windows -Recurse -force -ErrorAction SilentlyContinue
$a = $stopwatch.Elapsed.TotalSeconds

# Grouping files
$stopwatch.Restart()
$files | Group-Object -Property Extension | Where-Object -FilterScript { $_.Count -gt 10} | Sort-Object -Property Count -Descending | Out-Null
$b = $stopwatch.Elapsed.TotalSeconds

# C: Sorting files
$stopwatch.Restart()
$files | Sort-Object -Property Length | Select-Object -Property Length, Fullname | Out-Null 
$c = $stopwatch.Elapsed.TotalSeconds

# D: Sorting files, save to file
$stopwatch.Restart()
$files | Sort-Object -Property Length | Select-Object -Property Length, Fullname | Set-Content -Path $filename
Remove-Item -Path $filename 
$d = $stopwatch.Elapsed.TotalSeconds

# Display the results
$report = '{0:n1} sec.' 
[PSCustomObject]@{
    'Files count' = $files.Count
    'Finding files' = $report -f $a 
    'Grouping files' = $report -f $b
    'Sorting files (by length)' = $report -f $c 
    'Sorting files (by length), write to file' = $report -f $d 
} | Format-Table -AutoSize