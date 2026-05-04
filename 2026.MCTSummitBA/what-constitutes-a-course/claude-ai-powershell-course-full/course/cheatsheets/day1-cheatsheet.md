# Day 1 Cheat Sheet — Foundations

## The discoverability trio

| Cmdlet         | Answers                              |
|----------------|--------------------------------------|
| `Get-Command`  | **What** commands exist?             |
| `Get-Help`     | **How** do I use one?                |
| `Get-Member`   | **What can** this object do?         |

## Version check

```powershell
$PSVersionTable                 # PSVersion, PSEdition (Desktop vs Core)
Get-Command pwsh, powershell    # which binaries are installed
```

## Help first-use setup

```powershell
Update-Help -Force -ErrorAction SilentlyContinue
Get-Help Get-Service -Examples
Get-Help Get-Service -Online          # opens learn.microsoft.com
Get-Help about_Operators              # conceptual topics
```

## Verb-Noun grammar

```
<Verb>-<Noun>  [-Parameter Value]  [-Parameter:$true]
```

Approved verbs: `Get-Verb`. Common ones: Get, Set, New, Remove, Start, Stop, Add, Import, Export, Test, Invoke.

## Pipeline — objects, not text

```powershell
Get-Process | Get-Member                  # discover the object
Get-Process | Select-Object Name, Id, CPU # pick columns
Get-Service | Where-Object Status -eq Running
```

**Rule:** `Format-*` goes last. For CSV/JSON use `Select-Object` then `Export-*`.

## `$PROFILE` — your permanent setup

```powershell
$PROFILE
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
code $PROFILE
```

Starter content:

```powershell
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
```

## Execution policy — seatbelt, not a lock

```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## First script

```powershell
# hello.ps1
param([string] $Name = 'World')
"Hello, $Name!"
"PowerShell $($PSVersionTable.PSVersion)"
```

Run: `.\hello.ps1 -Name 'Anna'`

## Common aliases to remember — and then forget

| Alias | Real cmdlet       |
|-------|-------------------|
| `ls`, `dir` | `Get-ChildItem` |
| `cd`        | `Set-Location`  |
| `ps`        | `Get-Process`   |
| `gsv`       | `Get-Service`   |
| `?`         | `Where-Object`  |
| `%`         | `ForEach-Object`|
| `select`    | `Select-Object` |
| `sort`      | `Sort-Object`   |

**In scripts, spell the cmdlet out. Aliases are for interactive use only.**

## F8 workflow

1. Open a `.md` or `.ps1` in VSCode
2. Click a line inside a `powershell` code block
3. Press **F8** — line runs in the Integrated Console
4. Select multiple lines → F8 runs them as a block
