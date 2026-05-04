---
marp: true
theme: noble-blue
paginate: true
title: "Day 3 — Variables, Scripting, Remoting, Jobs"
---

<!-- _class: title -->

# PowerShell 7 for IT Administrators
## Day 3 — Variables, Scripting, Remoting, Jobs

---

## Where we are

- **Days 1–2:** everything interactive — type, pipe, inspect
- **Today:** save what we type, parameterise it, run it elsewhere
- **Tomorrow:** apply all of it to AD and EntraID

> Note: advanced function authoring, parameter sets, and `ShouldProcess`
> are covered in the follow-on course. Today we write **simple, useful scripts.**

---

<!-- _class: section -->

# Part 1
## Variables, arrays, hashtables

---

## Variables

```powershell
$name  = 'Anna'
$count = 42
$today = Get-Date
```

- Start with `$`
- **Dynamically typed** — the type is inferred from the value
- Names are case-insensitive; use `camelCase` or `PascalCase`, not `snake_case`

Inspect:

```powershell
$name.GetType().FullName     # System.String
$count.GetType().FullName    # System.Int32
```

---

## Type it if it matters

```powershell
[int]    $port     = 443
[string] $hostname = 'dc01'
[uint32] $flags    = 0x0001
[bool]   $enabled  = $true
```

Why bother?
- Self-documenting intent
- Early failure if a caller passes junk
- Bitwise arithmetic needs **unsigned** types (`[uint32]`) to avoid sign-extension bugs

---

## Arrays

```powershell
$colors = @('red', 'green', 'blue')
$colors[0]          # red
$colors[-1]         # blue
$colors.Count       # 3
$colors += 'yellow' # returns a NEW array
```

Ranges:

```powershell
$nums = 1..10
$letters = 'a'..'e'
```

> Appending with `+=` rebuilds the array each time. For >1000 items,
> use `[System.Collections.Generic.List[object]]::new()` instead.

---

## Hashtables

```powershell
$user = @{
    Name  = 'Anna Schmidt'
    Dept  = 'Sales'
    Id    = 42
}

$user['Name']        # access by key
$user.Dept           # dot also works
$user.Keys
$user.Add('City', 'Duisburg')
```

Ordered hashtable (preserves insertion order):

```powershell
$config = [ordered]@{
    Server = 'LON-DC1'
    Port   = 443
}
```

---

## PSCustomObject — the admin's friend

Build real objects from data:

```powershell
$report = [pscustomobject]@{
    Computer = $env:COMPUTERNAME
    User     = $env:USERNAME
    Date     = Get-Date
    PSVersion = $PSVersionTable.PSVersion.ToString()
}

$report | Format-List
$report | Export-Csv report.csv -NoTypeInformation
```

Use this instead of `Write-Host` for anything you want to pipe or export.

---

## Splatting — pass parameters as a hashtable

Painful:

```powershell
New-ADUser -Name 'Anna' -SamAccountName 'aschmidt' `
           -GivenName 'Anna' -Surname 'Schmidt' `
           -UserPrincipalName 'aschmidt@adatum.com' `
           -Path 'OU=Sales,DC=adatum,DC=com' -Enabled $true
```

Beautiful:

```powershell
$userParams = @{
    Name              = 'Anna'
    SamAccountName    = 'aschmidt'
    GivenName         = 'Anna'
    Surname           = 'Schmidt'
    UserPrincipalName = 'aschmidt@adatum.com'
    Path              = 'OU=Sales,DC=adatum,DC=com'
    Enabled           = $true
}
New-ADUser @userParams
```

`@` instead of `$` tells PowerShell: "spread this into parameters".

---

<!-- _class: section -->

# Part 2
## Scripts and flow control

---

## From command to `.ps1`

A script is just a file with commands in it.

```powershell
# hello.ps1
param(
    [string] $Name = 'World'
)
"Hello, $Name!"
"PowerShell $($PSVersionTable.PSVersion)"
```

Run it:

```powershell
.\hello.ps1
.\hello.ps1 -Name 'Thorsten'
```

---

<!-- _class: history -->

## Execution policy — a short history

- Introduced in PowerShell 1.0 (2006) in response to ILOVEYOU-era VBScript fear
- **Not a security boundary** — it's a "seatbelt", easily bypassed
- Default on Windows clients: `Restricted` (no scripts at all)
- Default on servers: `RemoteSigned` (local OK, downloaded needs signature)

```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

> Microsoft's own docs describe execution policy as a *"user convenience feature, not a security system."*

---

## Flow control: `if` / `elseif` / `else`

```powershell
$svc = Get-Service Spooler

if ($svc.Status -eq 'Running') {
    'Spooler is running'
} elseif ($svc.Status -eq 'Stopped') {
    'Spooler is stopped'
} else {
    "Spooler is in state: $($svc.Status)"
}
```

---

## `switch` — the multi-arm if

```powershell
switch ($svc.Status) {
    'Running'     { 'OK'         ; break }
    'Stopped'     { 'Start me'   ; break }
    'StartPending'{ 'Wait a bit' ; break }
    default       { 'Unexpected' }
}
```

Wildcards and regex:

```powershell
switch -Wildcard ($hostname) {
    'LON-*' { 'London site' }
    'DUS-*' { 'Duesseldorf site' }
}
```

---

## Loops

```powershell
# foreach — most common
foreach ($svc in Get-Service) {
    if ($svc.Status -eq 'Stopped') { $svc.Name }
}

# for — when you need the index
for ($i = 0; $i -lt 5; $i++) { "Attempt $i" }

# while / do-while
$tries = 0
do {
    $tries++
    Start-Sleep 1
} while ($tries -lt 3)
```

`foreach` keyword ≠ `ForEach-Object` cmdlet — but both exist.

---

## Error handling: `try` / `catch`

Terminating errors stop the script; non-terminating don't.

```powershell
try {
    Get-Content 'C:\does-not-exist.txt' -ErrorAction Stop
} catch {
    Write-Warning "Failed: $($_.Exception.Message)"
} finally {
    'Cleanup happens regardless'
}
```

Key flag: **`-ErrorAction Stop`** upgrades non-terminating errors to terminating.

---

## Write-* family — use the right one

| Cmdlet        | Goes to   | Use for                              |
|---------------|-----------|--------------------------------------|
| `Write-Output` | pipeline  | the thing the script produces        |
| `Write-Verbose` | verbose stream | diagnostics (off by default)    |
| `Write-Warning` | warning stream | something's off, but keep going |
| `Write-Error`   | error stream   | something's wrong               |
| `Write-Host`    | screen only    | user interaction (prompts, colour) |

**Never `Write-Host` data you want to pipe.** Use `Write-Output` or just emit the object.

---

<!-- _class: section -->

# Part 3
## Modules

---

## Finding and installing modules

```powershell
Find-Module Microsoft.Graph.Users        # search PSGallery
Install-Module Microsoft.Graph -Scope CurrentUser
Get-Module Microsoft.Graph* -ListAvailable
Import-Module Microsoft.Graph.Users
```

- **Scope CurrentUser** — no admin needed, installs to `$HOME\Documents\PowerShell\Modules`
- **Scope AllUsers** — admin needed, installs to `$env:ProgramFiles\PowerShell\Modules`

---

## PSResourceGet — the next generation

The classic `PowerShellGet` v2 is being replaced by **Microsoft.PowerShell.PSResourceGet**.

```powershell
Install-Module Microsoft.PowerShell.PSResourceGet
Find-PSResource Microsoft.Graph
Install-PSResource Microsoft.Graph -Scope CurrentUser
```

Faster, better dependency handling, drop-in successor. Keep an eye on it — `Install-Module` will eventually retire.

---

<!-- _class: section -->

# Part 4
## Remoting

---

## Three flavours of remoting

| Cmdlet            | Scenario                                          |
|-------------------|----------------------------------------------------|
| `Invoke-Command`  | Run a block on one-or-many machines, get results  |
| `Enter-PSSession` | Open an interactive shell on a remote box         |
| `New-PSSession`   | Persistent session, reuse across multiple calls   |

All three work over:
- **WinRM** (classic, HTTP/HTTPS, firewall-managed)
- **SSH** — PowerShell 7 only, cross-platform

---

## One command, many machines

```powershell
Invoke-Command -ComputerName LON-DC1, LON-CL1 -ScriptBlock {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object CSName, Caption, LastBootUpTime
}
```

Results include a `PSComputerName` property so you know who said what.

---

## Persistent session

```powershell
$s = New-PSSession -ComputerName LON-DC1

Invoke-Command -Session $s -ScriptBlock { Get-Service DNS }
Invoke-Command -Session $s -ScriptBlock { Get-ADUser -Filter * | Measure-Object }

Remove-PSSession $s
```

Faster: one handshake, many calls.

---

## Interactive session

```powershell
Enter-PSSession -ComputerName LON-DC1
# prompt changes to:  [LON-DC1]: PS C:\> _
# do things as if you were logged in
Exit-PSSession
```

---

<!-- _class: gotcha -->

## Variables on the remote side

The script block runs on the remote machine — local variables don't travel
automatically.

```powershell
$svcName = 'Spooler'
Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-Service $svcName      # ← undefined over there
}
```

Fix with `$using:` or the `-ArgumentList` parameter:

```powershell
Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-Service $using:svcName
}
```

---

<!-- _class: section -->

# Part 5
## Background jobs

---

## `Start-Job` — fire and forget

```powershell
$job = Start-Job -ScriptBlock {
    Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum
}

Get-Job
Wait-Job    $job
Receive-Job $job
Remove-Job  $job
```

Jobs run in a separate PowerShell process. Results queue until you `Receive-Job`.

---

## Remote jobs

```powershell
Invoke-Command -ComputerName LON-DC1, LON-CL1 -AsJob -ScriptBlock {
    Get-CimInstance Win32_OperatingSystem
}

Get-Job | Wait-Job | Receive-Job
```

All target machines in parallel, results collected at the end.

---

## `ForEach-Object -Parallel` vs jobs

| Use                        | When                                    |
|----------------------------|-----------------------------------------|
| `ForEach-Object -Parallel` | CPU-bound or I/O-bound batch, same box  |
| `Start-Job`                | Long-running, survive this prompt       |
| `Invoke-Command -AsJob`    | Many remote machines, collect later     |

For most admin work, `-Parallel` is the simplest win.

---

<!-- _class: lab -->

# Lab 5
## From one-liners to a script

**Goal:** Take yesterday's best pipeline and turn it into a parameterised
`.ps1` with error handling that emits `PSCustomObject`s.

**Duration:** ~60 minutes

Open `labs/lab05-scripting.md`.

---

<!-- _class: lab -->

# Lab 6
## Remoting in anger

**Goal:** Run your health-check script against the DC via `Invoke-Command`,
collect results from multiple machines, persist them as CliXml.

**Duration:** ~60 minutes

Open `labs/lab06-functions-remoting.md`.

---

## Day 3 recap

- Types matter for intent and for bitwise work (`[uint32]`)
- `PSCustomObject` + splatting = clean, readable scripts
- Execution policy is a seatbelt, not a lock
- `try/catch` with `-ErrorAction Stop` handles real errors
- `Invoke-Command` scales one-liners to thousands of machines
- `$using:` carries local variables into remote blocks
- `-Parallel`, `Start-Job`, `-AsJob` — three kinds of concurrency

---

<!-- _class: title -->

# End of Day 3
## Tomorrow: AD and EntraID, in hybrid harmony
