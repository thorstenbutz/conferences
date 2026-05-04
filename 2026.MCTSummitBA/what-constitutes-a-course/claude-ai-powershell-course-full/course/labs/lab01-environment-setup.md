# Lab 1 — Environment setup & orientation

**Duration:** ~60 minutes
**Target machine:** `LON-CL1` (Windows 11 client)
**Prerequisites:** logged in as `Adatum\Administrator` with internet access

---

## Goals

By the end of this lab you will:

1. Confirm Windows PowerShell 5.1 and PowerShell 7 coexist on the same box
2. Install VSCode and the PowerShell extension (if not already present)
3. Run your first cmdlets and press **F8** for the first time
4. Create and populate your `$PROFILE`
5. Briefly look at — and then close — the ISE

---

## How to use this lab

Every code block tagged `powershell` is meant to be run.

- Open this `.md` file in VSCode
- Click inside any line of a `powershell` fence
- Press **F8** to run that line in the Integrated Console
- Select multiple lines and F8 to run them as a block

The Integrated Console is, by default, **PowerShell 7** if the extension is installed.

---

## Exercise 1 — Which PowerShell do I have?

Open a classic Windows PowerShell 5.1 window first. Start menu → "Windows PowerShell" (the blue one).

```powershell
$PSVersionTable
```

Note the values: `PSVersion` should start with **5.1**, `PSEdition` should be **Desktop**.

```powershell
$Host.Name
$PSHome
```

Now close that window and open **PowerShell 7**. Start menu → "PowerShell 7" (the black icon, `pwsh`). If it's not there, download from <https://github.com/PowerShell/PowerShell/releases/latest> and install the MSI.

```powershell
$PSVersionTable
```

This time `PSVersion` should be **7.x** and `PSEdition` should be **Core**.

```powershell
Get-Command pwsh, powershell | Select-Object Name, Source
```

Both executables exist. They are **not** the same program.

---

## Exercise 2 — VSCode and the PowerShell extension

If VSCode is not installed:

```powershell
winget install --id Microsoft.VisualStudioCode -e --source winget
```

Launch VSCode. Install the PowerShell extension:

- `Ctrl+Shift+X` to open Extensions
- Search for **PowerShell** (publisher: Microsoft)
- Click **Install**

Restart VSCode.

Open the Integrated Terminal (`Ctrl+``). The top of the terminal should say **PowerShell Integrated Console** and `$PSVersionTable` should show version 7.x.

If it shows 5.1, open Settings (`Ctrl+,`), search `powershell default version`, and set the path to:

```
C:\Program Files\PowerShell\7\pwsh.exe
```

Restart VSCode.

---

## Exercise 3 — Your first cmdlets

In the Integrated Console (or by F8-ing these blocks from this lab file):

```powershell
Get-Date
```

```powershell
Get-Process | Select-Object -First 5
```

```powershell
Get-Service | Where-Object Status -eq Running | Select-Object -First 10
```

```powershell
Get-ChildItem C:\ | Select-Object Name, Mode, LastWriteTime
```

Look at the output. Every row is an **object** with named properties.

---

## Exercise 4 — Discover anything

The discoverability trio. Memorise these three.

```powershell
Get-Command *-Service
```

```powershell
Get-Help Get-Service
```

If that prints "help content not available", run (as administrator once per machine):

```powershell
Update-Help -Force -ErrorAction SilentlyContinue
```

Then:

```powershell
Get-Help Get-Service -Examples
Get-Help Get-Service -Full
Get-Help Get-Service -Online
```

And the third member of the trio:

```powershell
Get-Service | Get-Member
```

Scroll through the output. Note **MemberType**: properties vs methods.

---

## Exercise 5 — Create your `$PROFILE`

```powershell
$PROFILE
Test-Path $PROFILE
```

Path exists but the file probably doesn't. Create it:

```powershell
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
```

Open it in VSCode:

```powershell
code $PROFILE
```

Paste the following starter content, save, then restart VSCode (or just `. $PROFILE` to reload):

```powershell
# ---- PSReadLine tweaks -------------------------------------------------------
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab         -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow     -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow   -Function HistorySearchForward

# ---- Handy aliases -----------------------------------------------------------
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String

# ---- Prompt banner -----------------------------------------------------------
"PowerShell $($PSVersionTable.PSVersion) on $([System.Environment]::OSVersion.VersionString)"
```

Reload without restarting:

```powershell
. $PROFILE
```

Start typing `Get-Se` — you should see grey autocomplete from history and a list of matches. That's PSReadLine earning its keep.

---

## Exercise 6 — Look at the ISE (once, briefly)

Open the **Windows PowerShell ISE** from the Start menu. This is the only place in the course we'll touch it.

```powershell
$PSVersionTable
```

Notice:

- `PSVersion` is 5.1. The ISE **cannot run PowerShell 7.**
- No Git integration
- No extensions
- Last feature released: 2017

Close the ISE. We'll use VSCode for everything going forward.

---

## Exercise 7 — Set execution policy (CurrentUser scope)

Check your current policy:

```powershell
Get-ExecutionPolicy -List
```

If `CurrentUser` is `Undefined` or `Restricted`, set it to `RemoteSigned`:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

Confirm:

```powershell
Get-ExecutionPolicy -List
```

---

## Exercise 8 — Write your first `.ps1`

In VSCode, create a new file called `hello.ps1` on your Desktop:

```powershell
# hello.ps1
param(
    [string] $Name = 'World'
)

"Hello, $Name!"
"You are running PowerShell $($PSVersionTable.PSVersion) as $env:USERNAME."
```

Save. In the Integrated Console:

```powershell
Set-Location "$HOME\Desktop"
.\hello.ps1
.\hello.ps1 -Name 'Thorsten'
```

Congratulations — you've written, saved, and run a PowerShell script.

---

## Check yourself

Without looking back:

1. Which executable launches PowerShell 7?
2. Which `$PSVersionTable` field tells you "Desktop" vs "Core"?
3. Name the three cmdlets of the discoverability trio.
4. What keystroke runs the selected line in VSCode?
5. Why won't `Get-WmiObject` work in PowerShell 7?

_(Answers: `pwsh.exe` / `PSEdition` / `Get-Command`, `Get-Help`, `Get-Member` / `F8` / it was removed in PS 6 — use `Get-CimInstance`.)_

---

## Wrap-up

You now have a working lab environment. Keep VSCode open — every lab from
here on assumes you have it with the PowerShell extension active and
F8 ready to fire.
