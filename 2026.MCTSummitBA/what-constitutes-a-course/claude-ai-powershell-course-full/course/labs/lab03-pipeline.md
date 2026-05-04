# Lab 3 — Pipeline administration

**Duration:** ~75 minutes
**Target machine:** `LON-CL1`
**Prerequisites:** Labs 1–2 complete

---

## Goals

Build four reports using only the pipeline verbs:

1. **Process report** — top CPU consumers
2. **Service health** — all services, grouped by status
3. **Event log summary** — last 24h of warnings and errors
4. **Disk space alert** — any drive below a threshold

Then combine pieces into a single "system snapshot" script.

---

## Exercise 1 — `Where-Object` basics

Simplified syntax works for one condition:

```powershell
Get-Service | Where-Object Status -eq 'Running'
Get-Process | Where-Object CPU   -gt 10
Get-ChildItem C:\Windows -File | Where-Object Length -gt 1MB
```

Scriptblock syntax for multi-part conditions:

```powershell
Get-Process | Where-Object { $_.CPU -gt 5 -and $_.Name -like 'chrome*' }

Get-Service |
    Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' }
```

That second one is useful — it finds services that **should** be running but aren't.

---

## Exercise 2 — `Select-Object`

Pick columns:

```powershell
Get-Process | Select-Object Name, Id, CPU, WorkingSet
```

Head / tail:

```powershell
Get-Process | Select-Object -First 5
Get-Process | Select-Object -Last 5
```

Skip rows:

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -Skip 3 -First 5
```

Unique:

```powershell
Get-Process | Select-Object -ExpandProperty Company -Unique | Sort-Object
```

Calculated column — round working set to MB with a friendly name:

```powershell
Get-Process |
    Select-Object Name, Id,
        @{ Name = 'Memory(MB)'; Expression = { [math]::Round($_.WorkingSet / 1MB, 1) } },
        @{ Name = 'CPU(s)';    Expression = { [math]::Round($_.CPU, 1) } } |
    Sort-Object 'Memory(MB)' -Descending |
    Select-Object -First 10
```

That's **Report 1 — top memory consumers** in one pipeline.

---

## Exercise 3 — `Sort-Object`

```powershell
Get-Process | Sort-Object Name
Get-Process | Sort-Object CPU -Descending
Get-Service | Sort-Object Status, Name          # primary, then secondary
```

---

## Exercise 4 — `Group-Object`

```powershell
Get-Service | Group-Object Status
Get-Service | Group-Object Status | Sort-Object Count -Descending
```

A nicer rendering:

```powershell
Get-Service |
    Group-Object Status |
    Select-Object Name, Count |
    Sort-Object Count -Descending
```

That's **Report 2 — service health breakdown.**

---

## Exercise 5 — `Measure-Object`

Count:

```powershell
Get-Process | Measure-Object
```

Stats on a numeric property:

```powershell
Get-Process |
    Measure-Object -Property WorkingSet -Sum -Average -Maximum -Minimum
```

Same thing but human-readable:

```powershell
$stats = Get-Process | Measure-Object WorkingSet -Sum -Average -Maximum
[pscustomobject]@{
    TotalMB  = [math]::Round($stats.Sum     / 1MB, 0)
    AverageMB = [math]::Round($stats.Average / 1MB, 1)
    MaxMB    = [math]::Round($stats.Maximum / 1MB, 0)
    Count    = $stats.Count
}
```

---

## Exercise 6 — `ForEach-Object`

Classic:

```powershell
1..5 | ForEach-Object { "iteration $_" }
'dc01', 'dc02', 'dc03' | ForEach-Object { Test-Connection $_ -Count 1 -Quiet }
```

PowerShell 7 parallel — try this on multiple services:

```powershell
'Spooler', 'BITS', 'W32Time' | ForEach-Object -Parallel {
    Get-Service $_ | Select-Object Name, Status, StartType
} -ThrottleLimit 3
```

Parallel shines when each iteration takes real time (network calls, file I/O).

---

## Exercise 7 — Report 3: event log summary

Last 24h of Errors and Warnings in the System log:

```powershell
$since = (Get-Date).AddHours(-24)

Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    Level     = 2, 3           # 2 = Error, 3 = Warning
    StartTime = $since
} -ErrorAction SilentlyContinue |
    Group-Object ProviderName |
    Select-Object Count, Name |
    Sort-Object Count -Descending |
    Select-Object -First 10
```

> **F8 tip:** the `FilterHashtable` pre-filters at the event-log level.
> Much faster than piping all events into `Where-Object`.

---

## Exercise 8 — Report 4: disk-space alert

```powershell
Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3" |
    Select-Object DeviceID,
        @{ N = 'SizeGB'; E = { [math]::Round($_.Size      / 1GB, 1) } },
        @{ N = 'FreeGB'; E = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ N = 'Free%';  E = { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } } |
    Sort-Object 'Free%'
```

Flag drives below 20 % free:

```powershell
Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3" |
    Where-Object { ($_.FreeSpace / $_.Size) -lt 0.20 } |
    Select-Object DeviceID,
        @{ N = 'FreeGB'; E = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ N = 'Free%';  E = { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } }
```

---

## Exercise 9 — Export

Save each report to CSV and JSON:

```powershell
$reportPath = "$HOME\Desktop\Lab3-Reports"
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null

# Top 10 memory consumers
Get-Process |
    Select-Object Name, Id,
        @{ N = 'Memory(MB)'; E = { [math]::Round($_.WorkingSet / 1MB, 1) } } |
    Sort-Object 'Memory(MB)' -Descending |
    Select-Object -First 10 |
    Export-Csv -Path "$reportPath\top-memory.csv" -NoTypeInformation

# Service health
Get-Service |
    Group-Object Status |
    Select-Object Name, Count |
    ConvertTo-Json |
    Set-Content "$reportPath\service-health.json"

Get-ChildItem $reportPath
```

Open the CSV in Excel (or VSCode) to confirm.

---

## Exercise 10 — Format vs export

See the Gotcha in action. This fails silently:

```powershell
# ⚠ Do not copy this pattern into production code
Get-Process |
    Format-Table Name, Id |
    Export-Csv "$HOME\Desktop\broken.csv" -NoTypeInformation

Get-Content "$HOME\Desktop\broken.csv" -TotalCount 5
```

Open the CSV — it's full of formatting metadata, not processes.

The right way: `Select-Object` for export, `Format-Table` only for the screen:

```powershell
Get-Process |
    Select-Object Name, Id |
    Export-Csv "$HOME\Desktop\fixed.csv" -NoTypeInformation

Get-Content "$HOME\Desktop\fixed.csv" -TotalCount 5
```

Remember: **filter left, format right**.

---

## Exercise 11 — Mini-challenge

Using only what you've learned today, produce a single pipeline that
outputs the **three services that have been running the longest** on this
machine, with their start time.

> Hint: you'll need `Get-CimInstance Win32_Service` and its
> `ProcessId` property, joined to `Get-Process`. Or look at
> `Get-Service | Get-Member` for something simpler.

Sample solution (don't peek until you've tried):

```powershell
Get-CimInstance Win32_Service -Filter "State = 'Running' AND ProcessId <> 0" |
    ForEach-Object {
        $p = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
        if ($p) {
            [pscustomobject]@{
                Name      = $_.Name
                StartTime = $p.StartTime
                Uptime    = (Get-Date) - $p.StartTime
            }
        }
    } |
    Sort-Object Uptime -Descending |
    Select-Object -First 3
```

---

## Check yourself

1. Which cmdlet comes **last** in a pipeline that's going to CSV?
2. How do you add a calculated column named `MB` that shows memory in megabytes?
3. What's the difference between `Select-Object -ExpandProperty Name` and `Select-Object Name`?
4. When should you use `ForEach-Object -Parallel` over a plain `foreach`?

_(Answers: `Export-Csv` / `@{ N='MB'; E={ $_.WorkingSet / 1MB } }` / the former returns the strings, the latter returns objects with a Name property / when iterations do real work — network calls, disk I/O.)_

---

## Wrap-up

Four reports, about 30 lines of code total. That's the efficiency of
object pipelines. Tomorrow we'll put these skills behind `param()` and
turn them into reusable scripts.
