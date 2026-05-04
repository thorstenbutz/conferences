# Lab 2 — Discovery & the help system

**Duration:** ~45 minutes
**Target machine:** `LON-CL1`
**Prerequisites:** Lab 1 complete

---

## Goals

By the end of this lab you will:

1. Find cmdlets you've never heard of using `Get-Command`
2. Read a cmdlet's help without leaving the console
3. Discover every property and method on an object with `Get-Member`
4. Solve small admin problems using only the discoverability trio

---

## Exercise 1 — `Get-Command`

```powershell
Get-Command
```

That's too many. Narrow it down by noun, verb, or both.

```powershell
Get-Command -Noun Service
Get-Command -Verb Get
Get-Command -Verb Get -Noun *Net*
```

Wildcards work too:

```powershell
Get-Command *-EventLog
Get-Command Get-*Computer*
```

Filter by module:

```powershell
Get-Command -Module Microsoft.PowerShell.Management |
    Measure-Object
```

---

## Exercise 2 — Approved verbs

Every cmdlet uses an **approved verb**. See the list:

```powershell
Get-Verb
Get-Verb | Sort-Object Group, Verb | Format-Table -GroupBy Group
```

Quick quiz — what verb should you use to:

- Retrieve data?       → `Get`
- Create a new thing?  → `New`
- Change an existing thing?  → `Set`
- Delete a thing?      → `Remove`
- Check something?     → `Test`

```powershell
Get-Verb Test
```

---

## Exercise 3 — `Get-Help`

If you haven't already:

```powershell
Update-Help -Force -ErrorAction SilentlyContinue
```

Four help depths:

```powershell
Get-Help Get-Service
Get-Help Get-Service -Detailed
Get-Help Get-Service -Full
Get-Help Get-Service -Examples
```

Examples are where most people start.

```powershell
Get-Help Get-Service -Online
```

This opens the browser at learn.microsoft.com — the docs are often fresher than the local help.

---

## Exercise 4 — About topics

`Get-Help` also carries conceptual documentation. Search with wildcards:

```powershell
Get-Help about_*
Get-Help about_Operators
Get-Help about_Arrays
Get-Help about_Variables
```

Quiz yourself — use `about_*` to answer:

```powershell
Get-Help about_Comparison_Operators
```

- Which operator is case-sensitive for `-eq`?
- What's the difference between `-like` and `-match`?

---

## Exercise 5 — `Get-Member`

Pick any cmdlet. Inspect what it returns:

```powershell
Get-Process | Get-Member
```

Split properties from methods:

```powershell
Get-Process | Get-Member -MemberType Property
Get-Process | Get-Member -MemberType Method
```

Try it on a few more:

```powershell
Get-Date    | Get-Member
Get-Service | Get-Member
(Get-ChildItem C:\ | Select-Object -First 1) | Get-Member
```

`Get-Member` is the **map** of an object's API. When you don't know what you can do with something, start here.

---

## Exercise 6 — Solve something real

Without looking anything up, use `Get-Command`, `Get-Help`, and `Get-Member`
to answer each question. Write the answer as a one-liner.

### 6.1 What command resolves a DNS name?

```powershell
Get-Command -Noun *Dns* -Verb Resolve
# Hint: the answer is Resolve-DnsName
Resolve-DnsName -Name microsoft.com
```

### 6.2 How many services are on this machine?

```powershell
Get-Service | Measure-Object
(Get-Service).Count
```

### 6.3 What's the newest file in your Downloads folder?

```powershell
Get-ChildItem "$HOME\Downloads" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
```

### 6.4 Which processes are using more than 200 MB of working set?

```powershell
Get-Process |
    Where-Object WorkingSet -gt 200MB |
    Sort-Object WorkingSet -Descending |
    Select-Object Name, Id,
        @{ N = 'MB'; E = { [math]::Round($_.WorkingSet / 1MB, 0) } }
```

### 6.5 Is a given TCP port open on a remote host?

```powershell
Get-Command -Noun NetConnection
Test-NetConnection -ComputerName microsoft.com -Port 443
```

### 6.6 How many days since this machine was last booted?

```powershell
$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
(New-TimeSpan -Start $boot).Days
```

### 6.7 Show the first 10 entries from the System event log

```powershell
Get-Command -Noun *Event*
Get-EventLog -LogName System -Newest 10   # PowerShell 5.1 style
# or the modern cross-platform equivalent:
Get-WinEvent  -LogName System -MaxEvents 10
```

### 6.8 What's the machine's current time zone?

```powershell
Get-TimeZone
(Get-TimeZone).Id
```

---

## Exercise 7 — Parameter sets

Many cmdlets have multiple "shapes". `Get-Help` shows them in **SYNTAX**:

```powershell
Get-Help Get-Process -Full
```

Look for **PARAMETER SETS** in the syntax block — you can only pick
parameters from one set at a time.

Example: `Get-Process` accepts either `-Name` or `-Id`, never both.

```powershell
Get-Process -Name pwsh
Get-Process -Id $PID
# Get-Process -Name pwsh -Id $PID   # ← would error
```

---

## Exercise 8 — Tab completion deep dive

These are keystrokes, not commands. Try them in the Integrated Console:

- Type `Get-Proc` → **Tab** — completes to `Get-Process`
- Type `Get-Process -` → **Tab** — cycles through parameters
- Type `Get-Service -Name Sp` → **Tab** — completes to `Spooler`
- Type `Get-Service | Select-Object -Property St` → **Tab** — lists properties!

That last one is magic — PSReadLine knows the pipeline type.

---

## Check yourself

Without looking back:

1. How do you list every cmdlet whose noun contains "Firewall"?
2. How do you read the `about_If` documentation?
3. How do you get just the method names for a given object?
4. How do you open the online docs for `Get-Service`?
5. What's the difference between `-Filter` on `Get-ADUser` and `Where-Object`?

_(Answers: `Get-Command -Noun *Firewall*` / `Get-Help about_If` / `... | Get-Member -MemberType Method` / `Get-Help Get-Service -Online` / `-Filter` runs on the server, `Where-Object` after everything comes back.)_

---

## Wrap-up

You now have a self-service reference system in the shell itself. Whenever
you're stuck for the rest of this course — and the rest of your career —
the answer usually begins with one of three commands.
