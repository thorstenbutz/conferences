# Day 3 Cheat Sheet — Variables, Scripting, Remoting

## Variables & types

```powershell
$name  = 'Anna'
[int]    $port  = 443
[uint32] $flags = 0x0003           # unsigned — safe for bitwise
[bool]   $ok    = $true
```

Check type: `$name.GetType().FullName`

## Arrays, hashtables, PSCustomObject

```powershell
$colors = @('red', 'green', 'blue')
$colors[0] ; $colors[-1] ; $colors.Count

$user = @{ Name = 'Anna'; Dept = 'Sales'; Id = 42 }
$cfg  = [ordered]@{ Server = 'DC1'; Port = 443 }

$row = [pscustomobject]@{
    Computer = $env:COMPUTERNAME
    Date     = Get-Date
}
```

## Splatting

```powershell
$p = @{
    Name           = 'aschmidt'
    SamAccountName = 'aschmidt'
    Enabled        = $true
}
New-ADUser @p        # @ = splat,  $ = read
```

## Flow control

```powershell
if ($x -eq 1) { '...' } elseif ($x -gt 1) { '...' } else { '...' }

switch ($x) {
    'a'        { 'letter a'; break }
    { $_ -gt 5 } { 'big' }
    default    { 'other' }
}

foreach ($item in $list) { ... }
for ($i = 0; $i -lt 5; $i++) { ... }
while ($cond) { ... }
```

## Error handling

```powershell
try {
    Get-Content 'missing.txt' -ErrorAction Stop
} catch {
    Write-Warning "Failed: $($_.Exception.Message)"
} finally {
    'Always runs'
}
```

**`-ErrorAction Stop`** turns non-terminating errors into catchable ones.

## Write-* streams

| Cmdlet           | Goes to      | Use for                       |
|------------------|--------------|-------------------------------|
| `Write-Output`   | pipeline     | what the script *produces*    |
| `Write-Verbose`  | verbose      | diagnostics (off by default)  |
| `Write-Warning`  | warning      | something off, but continuing |
| `Write-Error`    | error        | something wrong               |
| `Write-Host`     | screen only  | prompts, colour               |

**Never `Write-Host` data you want to pipe.**

## Script template

```powershell
<#
.SYNOPSIS Short description.
.EXAMPLE  .\MyScript.ps1 -Name foo
#>
param(
    [string[]] $ComputerName = $env:COMPUTERNAME,
    [int]      $TimeoutSec   = 30
)

foreach ($name in $ComputerName) {
    try {
        # ...
        [pscustomobject]@{ Computer = $name; Status = 'OK'  }
    } catch {
        [pscustomobject]@{ Computer = $name; Status = 'Err'; Error = $_.Exception.Message }
    }
}
```

## Remoting

```powershell
# one-shot
Invoke-Command -ComputerName LON-DC1 -ScriptBlock { Get-Service DNS }

# persistent
$s = New-PSSession -ComputerName LON-DC1
Invoke-Command -Session $s -ScriptBlock { ... }
Remove-PSSession $s

# interactive
Enter-PSSession -ComputerName LON-DC1 ; ... ; Exit-PSSession

# run a local script on a remote
Invoke-Command -ComputerName LON-DC1 -FilePath .\myscript.ps1
```

## `$using:` — ship local values into remote blocks

```powershell
$svc = 'DNS'
Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-Service $using:svc
}
```

## Parallelism

| Mechanism               | Fit                                      |
|-------------------------|------------------------------------------|
| `ForEach-Object -Parallel` | CPU or I/O batch on local machine      |
| `Start-Job`             | Long-running, outlives current prompt    |
| `Invoke-Command -AsJob` | Many remote machines, collect later      |

## Cleanup hygiene

```powershell
Get-PSSession  | Remove-PSSession
Get-CimSession | Remove-CimSession
Get-Job        | Remove-Job -Force
```
