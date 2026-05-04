# Day 2 Cheat Sheet — Pipeline, Providers, CIM

## Pipeline verbs

| Cmdlet            | Alias    | Purpose                        |
|-------------------|----------|--------------------------------|
| `Where-Object`    | `?`      | filter rows                    |
| `Select-Object`   | `select` | pick columns / first / last    |
| `Sort-Object`     | `sort`   | reorder                        |
| `Group-Object`    | `group`  | pivot by property              |
| `Measure-Object`  | `measure`| sum / avg / min / max / count  |
| `ForEach-Object`  | `%`      | act on each                    |

## Comparison operators

| Op          | Meaning                         |
|-------------|---------------------------------|
| `-eq`/`-ne` | equal / not equal               |
| `-gt`/`-lt` | greater / less                  |
| `-ge`/`-le` | greater-or-equal / less-or-equal|
| `-like`     | wildcard (`*`, `?`)             |
| `-match`    | regex                           |
| `-in`/`-contains` | membership                |
| `-not` / `!` | negation                       |

Prefix with `c` for case-sensitive (`-ceq`, `-clike`).

## Filter idioms

```powershell
Get-Service | Where-Object Status -eq 'Running'
Get-Process | Where-Object { $_.CPU -gt 5 -and $_.Name -like 'chrome*' }
```

## Calculated properties

```powershell
Get-Process |
    Select-Object Name, Id,
        @{ N = 'MB'; E = { [math]::Round($_.WorkingSet / 1MB, 1) } }
```

## Parallel iteration (PS 7)

```powershell
1..10 | ForEach-Object -Parallel {
    "thread $using:PSItem"
    Start-Sleep 1
} -ThrottleLimit 5
```

Use `$using:var` for outer variables inside `-Parallel` blocks.

## Format vs Export

| Goal         | Use                              |
|--------------|----------------------------------|
| Screen       | `Format-Table`, `Format-List`    |
| Excel/CSV    | `Select-Object` → `Export-Csv -NoTypeInformation` |
| APIs         | `ConvertTo-Json -Depth N`        |
| PS → PS      | `Export-Clixml` / `Import-Clixml`|

## Providers — data as drives

```powershell
Get-PSProvider
Get-PSDrive
Set-Location HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion
Set-Location Cert:\LocalMachine\My
Set-Location Env:
```

Same `Get-ChildItem` / `Get-ItemProperty` for all of them.

## Installed software (one-liner)

```powershell
'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' |
    ForEach-Object { Get-ChildItem $_ -EA 0 } |
    Get-ItemProperty |
    Where-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName
```

## CIM, not WMI

```powershell
Get-CimInstance Win32_OperatingSystem
Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"
Get-CimClass -ClassName Win32_*Disk*
```

- `Get-WmiObject` is **removed in PS 7** — don't teach it.
- CIM uses WS-Man (same port as PSRemoting).

## CIM sessions

```powershell
$s = New-CimSession -ComputerName LON-DC1, LON-SVR1
Get-CimInstance Win32_OperatingSystem -CimSession $s
Remove-CimSession $s
```

## Common `Win32_*` classes

| Class                       | What it tells you          |
|-----------------------------|-----------------------------|
| `Win32_OperatingSystem`     | version, boot time, install |
| `Win32_ComputerSystem`      | manufacturer, model, RAM    |
| `Win32_Processor`           | CPU model, cores, speed     |
| `Win32_BIOS`                | BIOS version, serial        |
| `Win32_LogicalDisk`         | drive letters, free space   |
| `Win32_NetworkAdapterConfiguration` | IP, MAC, DHCP      |
| `Win32_Service`             | services (extended info)    |
| `Win32_Process`             | processes (extended info)   |
