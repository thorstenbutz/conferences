# Lab 5 — From one-liners to a script

**Duration:** ~60 minutes
**Target machine:** `LON-CL1`
**Prerequisites:** Labs 1–4 complete

---

## Goals

1. Take yesterday's pipeline work and put it behind a `param()` block
2. Handle errors so the script doesn't die on the first bad machine
3. Emit `PSCustomObject` rows so the output is composable
4. Add verbose and warning output so callers can see what's happening

---

## Exercise 1 — Variables, types, and splatting

Warm-up. F8 each block, observe.

```powershell
$name  = 'LON-CL1'
$count = 42
$today = Get-Date
$name.GetType().FullName
$count.GetType().FullName
$today.GetType().FullName
```

Type assertions:

```powershell
[int]    $port     = 443
[string] $hostname = 'dc01'
[uint32] $flags    = 0x00000003
[bool]   $enabled  = $true
```

Bitwise sanity-check — why `[uint32]` matters:

```powershell
[int]    $signed   = 0x80000000    # this will error OR overflow
[uint32] $unsigned = 0x80000000
$unsigned -band 0xFFFF0000         # safe, predictable
```

---

## Exercise 2 — Hashtables and PSCustomObject

```powershell
$ht = @{ Name = 'Anna'; Dept = 'Sales'; Id = 42 }
$ht.Name
$ht['Dept']
$ht.Keys
$ht.Count
```

Ordered hashtable:

```powershell
$cfg = [ordered]@{
    Server = 'LON-DC1'
    Port   = 443
    UseSSL = $true
}
$cfg
```

PSCustomObject — this is what your scripts should output:

```powershell
$obj = [pscustomobject]@{
    Computer = $env:COMPUTERNAME
    User     = $env:USERNAME
    Date     = Get-Date
}
$obj
$obj | Get-Member
$obj | Export-Csv "$HOME\Desktop\obj.csv" -NoTypeInformation
```

---

## Exercise 3 — Splatting

Demo with `New-Item`:

```powershell
$p = @{
    Path     = "$HOME\Desktop\SplatDemo"
    ItemType = 'Directory'
    Force    = $true
}
New-Item @p
```

Splat with overrides:

```powershell
$common = @{ ErrorAction = 'Stop'; Verbose = $true }

Get-ChildItem @common -Path "$HOME\Desktop\SplatDemo"
```

Once you've used splatting you will never want to write a 6-parameter line
broken with back-ticks again.

---

## Exercise 4 — Your first real script

Create a new file: `$HOME\Desktop\Get-SystemSnapshot.ps1`.

```powershell
code "$HOME\Desktop\Get-SystemSnapshot.ps1"
```

Paste this:

```powershell
<#
.SYNOPSIS
    Collects a one-line snapshot of a Windows machine.
.EXAMPLE
    .\Get-SystemSnapshot.ps1
.EXAMPLE
    .\Get-SystemSnapshot.ps1 -ComputerName LON-DC1
#>
param(
    [string] $ComputerName = $env:COMPUTERNAME
)

$os  = Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName
$cs  = Get-CimInstance Win32_ComputerSystem  -ComputerName $ComputerName
$cpu = Get-CimInstance Win32_Processor       -ComputerName $ComputerName |
       Select-Object -First 1

[pscustomobject]@{
    ComputerName = $ComputerName
    OS           = $os.Caption
    LastBoot     = $os.LastBootUpTime
    UptimeHours  = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
    CPU          = $cpu.Name
    Cores        = $cpu.NumberOfCores
    MemoryGB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    CollectedAt  = Get-Date
}
```

Save. Test:

```powershell
Set-Location "$HOME\Desktop"
.\Get-SystemSnapshot.ps1
.\Get-SystemSnapshot.ps1 -ComputerName LON-DC1
```

---

## Exercise 5 — Error handling

Break it on purpose:

```powershell
.\Get-SystemSnapshot.ps1 -ComputerName DOES-NOT-EXIST
```

You'll get ugly red text. Add proper handling. Edit the script so CIM calls are wrapped:

```powershell
param(
    [string] $ComputerName = $env:COMPUTERNAME
)

try {
    $os  = Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
    $cs  = Get-CimInstance Win32_ComputerSystem  -ComputerName $ComputerName -ErrorAction Stop
    $cpu = Get-CimInstance Win32_Processor       -ComputerName $ComputerName -ErrorAction Stop |
           Select-Object -First 1
}
catch {
    Write-Warning "[$ComputerName] unreachable: $($_.Exception.Message)"
    return [pscustomobject]@{
        ComputerName = $ComputerName
        Status       = 'Error'
        Error        = $_.Exception.Message
    }
}

[pscustomobject]@{
    ComputerName = $ComputerName
    Status       = 'OK'
    OS           = $os.Caption
    LastBoot     = $os.LastBootUpTime
    UptimeHours  = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
    Cores        = $cpu.NumberOfCores
    MemoryGB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    CollectedAt  = Get-Date
}
```

Re-test both cases:

```powershell
.\Get-SystemSnapshot.ps1
.\Get-SystemSnapshot.ps1 -ComputerName DOES-NOT-EXIST
```

No red text. One object per call, every time. **This is what calling code expects.**

---

## Exercise 6 — Make it accept many machines

Edit the `param` block to accept an array:

```powershell
param(
    [string[]] $ComputerName = $env:COMPUTERNAME
)

foreach ($name in $ComputerName) {
    try {
        $os  = Get-CimInstance Win32_OperatingSystem -ComputerName $name -ErrorAction Stop
        $cs  = Get-CimInstance Win32_ComputerSystem  -ComputerName $name -ErrorAction Stop
        $cpu = Get-CimInstance Win32_Processor       -ComputerName $name -ErrorAction Stop |
               Select-Object -First 1

        [pscustomobject]@{
            ComputerName = $name
            Status       = 'OK'
            OS           = $os.Caption
            LastBoot     = $os.LastBootUpTime
            UptimeHours  = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
            Cores        = $cpu.NumberOfCores
            MemoryGB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
        }
    }
    catch {
        Write-Warning "[$name] unreachable: $($_.Exception.Message)"
        [pscustomobject]@{
            ComputerName = $name
            Status       = 'Error'
            Error        = $_.Exception.Message
        }
    }
}
```

Now run it across multiple machines:

```powershell
.\Get-SystemSnapshot.ps1 -ComputerName 'LON-CL1', 'LON-DC1', 'DOES-NOT-EXIST' |
    Format-Table ComputerName, Status, OS, UptimeHours, MemoryGB -AutoSize
```

One failure no longer poisons the whole report.

---

## Exercise 7 — Flow control

Conditional logic:

```powershell
$svc = Get-Service Spooler

if ($svc.Status -eq 'Running') {
    'OK'
} elseif ($svc.Status -eq 'Stopped') {
    'Needs start'
} else {
    "Odd state: $($svc.Status)"
}
```

`switch`:

```powershell
switch ($svc.Status) {
    'Running' { "$($svc.Name) OK" ; break }
    'Stopped' { "$($svc.Name) stopped"; break }
    default   { "$($svc.Name) unexpected: $_" }
}
```

Loops:

```powershell
foreach ($s in 'Spooler', 'BITS', 'W32Time') {
    $svc = Get-Service $s -ErrorAction SilentlyContinue
    if ($svc) { "$($svc.Name): $($svc.Status)" }
}
```

---

## Exercise 8 — Verbose output

Replace `Write-Host` instincts with `Write-Verbose`. Add to the top of the
script's `foreach` body:

```powershell
Write-Verbose "[$name] collecting CIM data"
```

Then:

```powershell
.\Get-SystemSnapshot.ps1 -ComputerName LON-CL1
.\Get-SystemSnapshot.ps1 -ComputerName LON-CL1 -Verbose
```

The verbose stream is quiet by default, shouty on demand. Exactly what you want in production.

> **Note:** for `-Verbose` to be recognised without you declaring it yourself,
> upgrade the script's `param` block later with `[CmdletBinding()]`. That's
> covered in the follow-on "Advanced Functions" course.

---

## Exercise 9 — Export the results

```powershell
$results = .\Get-SystemSnapshot.ps1 -ComputerName 'LON-CL1', 'LON-DC1'

$results | Export-Csv   "$HOME\Desktop\snapshot.csv" -NoTypeInformation
$results | ConvertTo-Json | Set-Content "$HOME\Desktop\snapshot.json"
$results | Export-Clixml "$HOME\Desktop\snapshot.xml"

Import-Clixml "$HOME\Desktop\snapshot.xml" |
    Where-Object Status -eq 'OK' |
    Sort-Object UptimeHours -Descending
```

All three formats, three reasons:

- CSV → Excel / any other tool
- JSON → downstream APIs
- CliXml → pass to the next PowerShell script with objects intact

---

## Check yourself

1. What do the `@` and `$` sigils do differently with a hashtable?
2. Why does the script use `foreach` instead of `ForEach-Object`?
3. What's the difference between `Write-Host` and `Write-Output`?
4. Why emit a `PSCustomObject` instead of a formatted string?
5. What does `-ErrorAction Stop` do to a non-terminating error?

_(Answers: `$` reads the value, `@` splats it into a cmdlet's parameters / `foreach` is a language keyword, faster for already-collected data / `Write-Host` goes only to the screen, `Write-Output` (or bare emission) goes to the pipeline / objects can be filtered, sorted, exported, piped — strings can only be printed / upgrades it to terminating so `try/catch` can see it.)_

---

## Wrap-up

You've gone from one-liner to parameterised script with error handling,
verbose output, and object emission. That's the shape of every production
script you'll ever write. The follow-on course extends this into full
advanced functions with parameter sets and `ShouldProcess`.
