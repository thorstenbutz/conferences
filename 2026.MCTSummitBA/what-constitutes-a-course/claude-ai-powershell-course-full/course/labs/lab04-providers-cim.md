# Lab 4 — PSProviders + CIM

**Duration:** ~60 minutes
**Target machine:** `LON-CL1`
**Prerequisites:** Labs 1–3 complete

---

## Goals

1. Navigate the registry, certificate store, and environment variables through PSDrives
2. Produce an **installed-software report** from the registry
3. Produce an **expiring-certificates report** from `Cert:`
4. Build a **system inventory** from CIM queries

---

## Exercise 1 — Inventory the providers

```powershell
Get-PSProvider
Get-PSDrive
```

You should see providers for `FileSystem`, `Registry`, `Certificate`, `Alias`,
`Environment`, `Variable`, and `Function`. Each one exposes one or more drives.

Filter to just Registry drives:

```powershell
Get-PSDrive -PSProvider Registry
```

---

## Exercise 2 — The registry is just a drive

```powershell
Set-Location HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion
Get-ChildItem
Get-Location
```

Read a value:

```powershell
Get-ItemProperty -Path . -Name ProgramFilesDir
```

Read all values of the current key:

```powershell
Get-ItemProperty -Path .
```

Back to the root:

```powershell
Set-Location C:\
```

---

## Exercise 3 — Report: installed software

The registry's "Uninstall" hive is where the **Programs and Features** list in Windows lives.

```powershell
$uninstallPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'

Get-ChildItem $uninstallPath |
    Get-ItemProperty |
    Where-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName
```

On 64-bit Windows there's also a 32-bit hive:

```powershell
$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

$software = $paths | ForEach-Object {
    Get-ChildItem $_ -ErrorAction SilentlyContinue |
        Get-ItemProperty |
        Where-Object DisplayName |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
}

$software | Sort-Object DisplayName | Format-Table -AutoSize
$software.Count
```

Export it:

```powershell
$software |
    Sort-Object DisplayName |
    Export-Csv "$HOME\Desktop\installed-software.csv" -NoTypeInformation
```

---

## Exercise 4 — The certificate store

```powershell
Set-Location Cert:\
Get-ChildItem
Set-Location Cert:\LocalMachine\My
Get-ChildItem
```

Inspect a cert:

```powershell
Get-ChildItem Cert:\LocalMachine\My | Select-Object -First 1 | Format-List *
```

---

## Exercise 5 — Report: expiring certificates

```powershell
$threshold = (Get-Date).AddDays(90)

Get-ChildItem Cert:\LocalMachine -Recurse |
    Where-Object { $_.NotAfter -and $_.NotAfter -lt $threshold } |
    Select-Object Subject, Issuer, NotAfter,
        @{ N = 'DaysLeft'; E = { ([datetime]$_.NotAfter - (Get-Date)).Days } },
        Thumbprint |
    Sort-Object NotAfter
```

Pipe into an HTML report:

```powershell
Get-ChildItem Cert:\LocalMachine -Recurse |
    Where-Object { $_.NotAfter -and $_.NotAfter -lt (Get-Date).AddDays(180) } |
    Select-Object Subject, Issuer, NotAfter, Thumbprint |
    Sort-Object NotAfter |
    ConvertTo-Html -Title 'Expiring certificates' |
    Set-Content "$HOME\Desktop\expiring-certs.html"

Invoke-Item "$HOME\Desktop\expiring-certs.html"
```

---

## Exercise 6 — Environment, Variable, Alias drives

Environment variables:

```powershell
Set-Location Env:
Get-ChildItem | Sort-Object Name
$env:USERNAME
$env:COMPUTERNAME
Set-Location C:\
```

PowerShell variables have their own drive:

```powershell
Get-ChildItem Variable: | Select-Object -First 10
$PSVersionTable.PSVersion            # same as:
(Get-Item Variable:PSVersionTable).Value.PSVersion
```

Aliases too:

```powershell
Get-ChildItem Alias: | Select-Object -First 10
```

---

## Exercise 7 — CIM discovery

```powershell
Get-CimClass -ClassName Win32_*Disk*
Get-CimClass -ClassName Win32_Computer*
```

List CIM namespaces (advanced, just to see):

```powershell
Get-CimInstance -Namespace root -ClassName __Namespace |
    Select-Object Name -First 10
```

---

## Exercise 8 — Report: system inventory

A one-stop PSCustomObject that captures the machine's identity:

```powershell
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1

$inventory = [pscustomobject]@{
    ComputerName = $env:COMPUTERNAME
    OS           = $os.Caption
    OSVersion    = $os.Version
    Architecture = $os.OSArchitecture
    LastBoot     = $os.LastBootUpTime
    Uptime       = (Get-Date) - $os.LastBootUpTime
    Manufacturer = $cs.Manufacturer
    Model        = $cs.Model
    CPU          = $cpu.Name
    CPUCores     = $cpu.NumberOfCores
    MemoryGB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    BIOSVersion  = $bios.SMBIOSBIOSVersion
    BIOSSerial   = $bios.SerialNumber
    PSVersion    = $PSVersionTable.PSVersion.ToString()
    CollectedAt  = Get-Date
}

$inventory | Format-List
```

Export it:

```powershell
$inventory | Export-Clixml "$HOME\Desktop\inventory.xml"
$restored = Import-Clixml "$HOME\Desktop\inventory.xml"
$restored.Uptime      # still a real TimeSpan object
```

---

## Exercise 9 — Disk layout via CIM

```powershell
Get-CimInstance Win32_LogicalDisk |
    Select-Object DeviceID, DriveType, FileSystem,
        @{ N = 'SizeGB'; E = { [math]::Round($_.Size      / 1GB, 1) } },
        @{ N = 'FreeGB'; E = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        VolumeName |
    Format-Table -AutoSize
```

DriveType code table:

| Value | Meaning         |
|-------|-----------------|
| 2     | Removable       |
| 3     | Fixed (hard disk) |
| 4     | Network         |
| 5     | CD-ROM          |

---

## Exercise 10 — Network adapters via CIM

```powershell
Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled = true" |
    Select-Object Description, MACAddress, IPAddress, DHCPEnabled, DHCPServer
```

---

## Exercise 11 — CIM sessions (bonus if time permits)

Create a reusable session to the DC, then hit it twice:

```powershell
$cim = New-CimSession -ComputerName LON-DC1

Get-CimInstance Win32_OperatingSystem  -CimSession $cim |
    Select-Object PSComputerName, Caption, LastBootUpTime

Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3" -CimSession $cim |
    Select-Object PSComputerName, DeviceID,
        @{ N = 'FreeGB'; E = { [math]::Round($_.FreeSpace / 1GB, 1) } }

Remove-CimSession $cim
```

One handshake, two queries. For dozens of servers this is a huge win.

---

## Check yourself

1. Which command lists every installed program, 64-bit and 32-bit?
2. Where does `Cert:\LocalMachine\My` come from — file system or a provider?
3. Why is `Get-CimInstance` preferred over `Get-WmiObject`?
4. What does `DriveType = 3` mean in `Win32_LogicalDisk`?
5. How do you reuse one connection for multiple CIM queries?

_(Answers: two Uninstall hives, under `HKLM:\SOFTWARE` and `HKLM:\SOFTWARE\WOW6432Node` / a Certificate provider drive / CIM uses WS-Man, works in PS 7, cross-platform — WMI uses DCOM and is gone in PS 7 / fixed hard disk / `New-CimSession`.)_

---

## Wrap-up

You now have three reusable scripts on your Desktop — installed software,
expiring certs, and a full system inventory — all built from provider
navigation and CIM queries. Same shapes will work against any Windows machine
via `New-CimSession`. Tomorrow we'll wrap them in `param()` blocks and error
handling.
