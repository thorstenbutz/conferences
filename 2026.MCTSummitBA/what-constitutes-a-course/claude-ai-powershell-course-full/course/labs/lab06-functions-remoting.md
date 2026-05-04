# Lab 6 — Remoting and jobs

**Duration:** ~60 minutes
**Target machines:** `LON-CL1` (driver) and `LON-DC1` (target)
**Prerequisites:** Labs 1–5 complete, PSRemoting enabled on `LON-DC1`

> **Instructor note:** In the standard AZ-040 topology, remoting is already
> enabled on the DC. If not, run `Enable-PSRemoting -Force` on `LON-DC1` from
> an elevated prompt.

---

## Goals

1. Run a command on a remote machine with `Invoke-Command`
2. Open and close a persistent `PSSession`
3. Use `$using:` to carry local variables to the remote block
4. Parallelise with `ForEach-Object -Parallel` and `Start-Job`
5. Run yesterday's `Get-SystemSnapshot.ps1` across both lab machines

---

## Exercise 1 — Test connectivity

```powershell
Test-NetConnection -ComputerName LON-DC1 -Port 5985       # WinRM HTTP
Test-NetConnection -ComputerName LON-DC1 -Port 22         # SSH (if enabled)
```

Try a simple remoting call:

```powershell
Invoke-Command -ComputerName LON-DC1 -ScriptBlock { $env:COMPUTERNAME }
```

If it prints `LON-DC1`, you're good. If it errors, stop and fix the WinRM
configuration before continuing.

---

## Exercise 2 — `Invoke-Command` one-shots

```powershell
Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-Service DNS | Select-Object Name, Status
}

Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, LastBootUpTime
}
```

Note the extra column: `PSComputerName`. The object tells you where it came from.

```powershell
Invoke-Command -ComputerName LON-CL1, LON-DC1 -ScriptBlock {
    [pscustomobject]@{
        PS   = $PSVersionTable.PSVersion.ToString()
        User = $env:USERNAME
    }
}
```

---

## Exercise 3 — Persistent sessions

One handshake, many calls:

```powershell
$s = New-PSSession -ComputerName LON-DC1

Invoke-Command -Session $s -ScriptBlock { Get-Service DNS  | Select Name, Status }
Invoke-Command -Session $s -ScriptBlock { Get-Service DHCP | Select Name, Status }
Invoke-Command -Session $s -ScriptBlock { (Get-Date).ToString('o') }

Get-PSSession
Remove-PSSession $s
```

---

## Exercise 4 — `Enter-PSSession`

Interactive shell inside the remote machine:

```powershell
Enter-PSSession -ComputerName LON-DC1
```

Your prompt changes:

```
[LON-DC1]: PS C:\Users\Administrator\Documents>
```

Type a few things:

```powershell
hostname
Get-ADDomain | Select-Object DNSRoot, DomainMode
Exit-PSSession
```

You're back on `LON-CL1`. Confirm:

```powershell
hostname
```

---

## Exercise 5 — `$using:` for local variables

```powershell
$svcName = 'DNS'

# WRONG — $svcName is empty over there
Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-Service $svcName -ErrorAction SilentlyContinue
}

# RIGHT — $using: ships the local value to the remote block
Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    Get-Service $using:svcName | Select-Object Name, Status, StartType
}
```

Works for arrays too:

```powershell
$names = 'DNS', 'DHCPServer', 'NTDS'

Invoke-Command -ComputerName LON-DC1 -ScriptBlock {
    foreach ($n in $using:names) {
        Get-Service $n -ErrorAction SilentlyContinue |
            Select-Object Name, Status
    }
}
```

---

## Exercise 6 — Run a local script remotely

This is the magic. You have `Get-SystemSnapshot.ps1` on `LON-CL1` from Lab 5.
Run it **against** `LON-DC1` by shipping the file:

```powershell
Invoke-Command -ComputerName LON-DC1 `
    -FilePath "$HOME\Desktop\Get-SystemSnapshot.ps1"
```

PowerShell copies the script over, runs it on the remote, and streams the
objects back.

If you want to pass parameters, combine with `-ArgumentList`:

```powershell
Invoke-Command -ComputerName LON-DC1 `
    -FilePath "$HOME\Desktop\Get-SystemSnapshot.ps1" `
    -ArgumentList 'LON-DC1'
```

> The script's own `-ComputerName` parameter is now "what it looks at from inside".
> Outer `-ComputerName` is "where to run it". Two different levels.

---

## Exercise 7 — ForEach-Object -Parallel

Sequential, slow when each call takes real time:

```powershell
Measure-Command {
    'LON-CL1', 'LON-DC1' | ForEach-Object {
        Test-Connection $_ -Count 2 -Quiet
    }
}
```

Parallel, fast:

```powershell
Measure-Command {
    'LON-CL1', 'LON-DC1' | ForEach-Object -Parallel {
        Test-Connection $_ -Count 2 -Quiet
    } -ThrottleLimit 5
}
```

Remember: inside the script block, outer variables need `$using:`.

```powershell
$timeout = 1

'LON-CL1', 'LON-DC1', 'DOES-NOT-EXIST' | ForEach-Object -Parallel {
    $result = Test-Connection $_ -Count 1 -TimeoutSeconds $using:timeout -Quiet
    [pscustomobject]@{
        Host   = $_
        Online = $result
    }
} -ThrottleLimit 10
```

---

## Exercise 8 — Background jobs

Fire and forget:

```powershell
$j = Start-Job -ScriptBlock {
    Start-Sleep 3
    Get-Process | Measure-Object
}

Get-Job
Wait-Job $j | Out-Null
Receive-Job $j
Remove-Job $j
```

Remote-as-job — dispatch work, come back later:

```powershell
$j = Invoke-Command -ComputerName LON-CL1, LON-DC1 -AsJob -ScriptBlock {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object CSName, Caption, LastBootUpTime
}

# do other things here...

$j | Wait-Job | Out-Null
$j | Receive-Job | Format-Table CSName, Caption, LastBootUpTime
$j | Remove-Job
```

---

## Exercise 9 — Combine everything

Run `Get-SystemSnapshot.ps1` across both lab machines, in parallel, collect
results, export.

```powershell
$targets = 'LON-CL1', 'LON-DC1'
$script  = "$HOME\Desktop\Get-SystemSnapshot.ps1"

$results = $targets | ForEach-Object -Parallel {
    Invoke-Command -ComputerName $_ -FilePath $using:script
} -ThrottleLimit 10

$results |
    Select-Object ComputerName, Status, OS, UptimeHours, MemoryGB |
    Sort-Object ComputerName |
    Format-Table -AutoSize

$results | Export-Csv "$HOME\Desktop\snapshots.csv" -NoTypeInformation
```

You've just built a parallel, remote, multi-machine reporting tool.
Scaling it from 2 machines to 200 is exactly the same code — just give `$targets`
a longer list.

---

## Exercise 10 — Clean up

```powershell
Get-PSSession | Remove-PSSession
Get-Job       | Remove-Job -Force
Get-CimSession | Remove-CimSession
```

Good hygiene. Lingering sessions eat WinRM quota.

---

## Check yourself

1. What extra property do remote results carry?
2. Why does `$svcName` inside an `Invoke-Command` block not see the outer variable without `$using:`?
3. When would you use `Invoke-Command -FilePath` rather than `-ScriptBlock`?
4. What's the difference between `Invoke-Command -AsJob` and `Start-Job`?
5. How do you limit parallel threads?

_(Answers: `PSComputerName` / the script block runs in a separate runspace on the remote machine — it has its own scope / when you want to execute an existing `.ps1` on the remote without copy-pasting it / `-AsJob` runs a remote command and tracks it as a job; `Start-Job` runs locally in a child process / `-ThrottleLimit` on `-Parallel` and `Invoke-Command`.)_

---

## Wrap-up

You can now run any piece of PowerShell against any WinRM-reachable Windows
box, in parallel, with structured results. That's the muscle behind every
enterprise PowerShell tool. Tomorrow we apply it to the real workloads:
Active Directory and EntraID.
