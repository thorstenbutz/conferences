---
marp: true
theme: noble-blue
paginate: true
title: "Day 2 — Pipeline, Providers, CIM/WMI"
---

<!-- _class: title -->

# PowerShell 7 for IT Administrators
## Day 2 — Pipeline, Providers, CIM/WMI

---

## Yesterday, today, tomorrow

- **Day 1** — shell, editor, objects, the discoverability trio
- **Today** — master the pipeline, navigate non-file data, query the system
- **Day 3** — variables, scripting, remoting, jobs

---

<!-- _class: section -->

# Part 1
## Pipeline mastery

---

## The four workhorses

| Cmdlet           | Alias         | Purpose                             |
|------------------|---------------|-------------------------------------|
| `Where-Object`   | `where`, `?`  | Keep rows that match a condition    |
| `Select-Object`  | `select`      | Pick columns / first / last / unique |
| `Sort-Object`    | `sort`        | Order the rows                      |
| `ForEach-Object` | `foreach`, `%`| Do something with each object       |

Plus two aggregators:

- `Group-Object`   — pivot by a property
- `Measure-Object` — sum / average / count

---

## `Where-Object` — filter

Modern (PS 3.0+) "simplified" syntax:

```powershell
Get-Service | Where-Object Status -eq Running
Get-Process | Where-Object CPU -gt 10
```

Classic scriptblock syntax — needed for complex conditions:

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 -and $_.Name -like 'chrome*' }
```

`$_` is the current pipeline object. `$PSItem` is its longer name.

---

## Comparison operators (they are not `==`)

| Operator | Meaning                  |
|----------|--------------------------|
| `-eq`    | equals                   |
| `-ne`    | not equals               |
| `-gt`    | greater than             |
| `-lt`    | less than                |
| `-ge` / `-le` | greater/less or equal |
| `-like`  | wildcard match (`*`, `?`) |
| `-match` | regex match              |
| `-in` / `-notin` | membership test  |
| `-contains` | collection contains   |

All case-**insensitive** by default. Prefix with `c` (`-ceq`) for case-sensitive.

---

## `Select-Object` — project

```powershell
Get-Process | Select-Object Name, Id, CPU
Get-Process | Select-Object -First 5
Get-Process | Select-Object -Last 5
Get-Process | Select-Object -Unique -Property ProcessName
```

Calculated properties — give a column any name and formula you want:

```powershell
Get-Process | Select-Object Name,
    @{ Name = 'Memory(MB)'; Expression = { [math]::Round($_.WorkingSet / 1MB, 1) } }
```

---

## `Sort-Object`

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
Get-ChildItem C:\Windows | Sort-Object Length -Descending
```

Sort on multiple properties:

```powershell
Get-Service | Sort-Object Status, Name
```

---

## `ForEach-Object` — act on each

```powershell
1..5 | ForEach-Object { "Hello #$_" }

Get-Service Spooler, BITS | ForEach-Object { Restart-Service $_.Name -WhatIf }
```

**PowerShell 7 superpower** — run iterations in parallel:

```powershell
1..10 | ForEach-Object -Parallel {
    "Thread $using:PSItem starting"
    Start-Sleep -Seconds 1
} -ThrottleLimit 5
```

Note the `$using:` scope modifier when referencing outer variables.

---

## `Group-Object` and `Measure-Object`

Pivot by a property:

```powershell
Get-Process | Group-Object Company | Sort-Object Count -Descending
```

Aggregate numeric data:

```powershell
Get-ChildItem C:\Windows -File |
    Measure-Object -Property Length -Sum -Average -Maximum
```

---

<!-- _class: gotcha -->

## Gotcha: filter left, format right

Every extra object you carry costs memory and time.

```powershell
# slow — filters AFTER getting everything
Get-Service | Where-Object Status -eq Stopped

# fast — many cmdlets have a -Filter or -Name parameter
Get-Service -Name 'Spooler'
Get-ADUser -Filter "Department -eq 'Sales'"
```

Rule of thumb: if a cmdlet has `-Filter`, use it. Otherwise,
`Where-Object` as soon as possible in the pipeline.

---

<!-- _class: section -->

# Part 2
## Formatting and export

---

## Format for humans, export for machines

For the screen:

```powershell
Get-Process | Format-Table Name, Id, CPU -AutoSize
Get-Service | Format-List Name, Status, StartType
Get-ChildItem | Format-Wide -Column 4
```

For files / downstream tools:

```powershell
Get-Process | Export-Csv   -Path procs.csv  -NoTypeInformation
Get-Process | ConvertTo-Json -Depth 3 | Set-Content procs.json
Get-Process | Export-Clixml -Path procs.xml  # round-trips full objects
```

---

## CSV vs JSON vs CliXml

| Format    | Good for                          | Round-trips objects? |
|-----------|-----------------------------------|----------------------|
| CSV       | Excel, spreadsheets, databases    | No — strings only    |
| JSON      | APIs, config files, other tooling | Partially            |
| CliXml    | PowerShell → PowerShell transfer  | **Yes — fully**      |

```powershell
$snap = Get-Process | Export-Clixml .\snap.xml
$restored = Import-Clixml .\snap.xml
$restored[0].GetType()   # still a Process (deserialized)
```

---

<!-- _class: section -->

# Part 3
## PSProviders and PSDrives

---

## Everything is a drive

PowerShell exposes non-file data through the **same cmdlets** you use for files.
A **provider** is an adapter; each provider surfaces **drives**.

```powershell
Get-PSProvider
Get-PSDrive
```

Expect to see: FileSystem, Registry, Certificate, Alias, Environment, Variable, Function.

---

## The pattern

```powershell
Set-Location C:\              # file system
Set-Location HKLM:\           # registry hive
Set-Location Cert:\           # certificate store
Set-Location Env:\            # environment variables

Get-ChildItem
```

Same `Get-ChildItem`, four very different data sources.

---

## Registry via PSDrive

```powershell
Set-Location HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall

Get-ChildItem |
    Get-ItemProperty |
    Where-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName
```

You just wrote an "installed software" report in five lines.

---

## Certificate store

```powershell
Get-ChildItem Cert:\LocalMachine\My |
    Where-Object NotAfter -lt (Get-Date).AddDays(90) |
    Select-Object Subject, NotAfter, Thumbprint
```

Expiring-certs report, also five lines.

---

## Environment variables

```powershell
Get-ChildItem Env:          # list all
$env:USERNAME               # read one
$env:MYVAR = 'hello'        # set for this session
Get-Item Env:PATH           # with the provider API
```

---

<!-- _class: section -->

# Part 4
## CIM and WMI

---

<!-- _class: history -->

## WMI → CIM, a short history

- **WMI** (Windows Management Instrumentation) ships with NT 4.0 (1998)
- Microsoft's implementation of DMTF's **CIM** (Common Information Model)
- Talks over **DCOM** — port-hostile, firewall-unfriendly
- 2012: PowerShell 3.0 adds `*-CimInstance` cmdlets
- CIM cmdlets use **WS-Man** (same transport as remoting) — firewall-friendly
- The old `Get-WmiObject` is **removed** in PowerShell 7

---

## Use CIM, not WMI

```powershell
# WMI — Windows PowerShell 5.1 only, do not teach
Get-WmiObject -Class Win32_OperatingSystem        # ← removed in PS 7

# CIM — works in 5.1 and 7, cross-platform-ready
Get-CimInstance -ClassName Win32_OperatingSystem
```

---

## What CIM is good for

Hardware, OS, BIOS, disks, network, services, processes — anything exposed
by the Windows management model.

```powershell
Get-CimInstance Win32_BIOS
Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"
Get-CimInstance Win32_ComputerSystem |
    Select-Object Manufacturer, Model,
        @{ N = 'Memory(GB)'; E = { [math]::Round($_.TotalPhysicalMemory / 1GB, 1) } }
```

Discover classes:

```powershell
Get-CimClass -ClassName Win32_*Disk*
```

---

## CIM sessions for many machines

```powershell
$servers = 'LON-DC1', 'LON-CL1'
$sessions = New-CimSession -ComputerName $servers

Get-CimInstance Win32_OperatingSystem -CimSession $sessions |
    Select-Object PSComputerName, Caption, LastBootUpTime

Remove-CimSession $sessions
```

One connection reused — much faster than one call per box.

---

<!-- _class: lab -->

# Lab 3
## Pipeline administration

**Goal:** Build four useful one-liners — process report, service health,
event log summary, disk-space alert — using only pipeline verbs.

**Duration:** ~75 minutes

Open `labs/lab03-pipeline.md`.

---

<!-- _class: lab -->

# Lab 4
## Providers + CIM

**Goal:** Produce an installed-software report from the registry,
an expiring-certificates report from `Cert:`, and a full system-inventory
one-liner via CIM.

**Duration:** ~60 minutes

Open `labs/lab04-providers-cim.md`.

---

## Day 2 recap

- Four pipeline verbs: **Where**, **Select**, **Sort**, **ForEach**
- Two aggregators: **Group** and **Measure**
- Filter left, format right, export with `Export-Csv` / `ConvertTo-Json`
- **Providers** make registry/certs/env/variables look like files
- **CIM** replaced WMI; `Get-WmiObject` is gone in PS 7
- `CimSession` = fast multi-machine queries

---

<!-- _class: title -->

# End of Day 2
## Tomorrow: from one-liner to script
