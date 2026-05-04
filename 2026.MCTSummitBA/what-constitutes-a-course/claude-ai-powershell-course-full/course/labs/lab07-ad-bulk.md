# Lab 7 — AD bulk provisioning

**Duration:** ~60 minutes
**Target machine:** `LON-CL1` (driver) → `LON-DC1` (AD target)
**Prerequisites:** Labs 1–6 complete, RSAT `ActiveDirectory` module installed, domain admin rights on `adatum.com`

---

## Goals

1. Read and write the directory with the `ActiveDirectory` module
2. Use `-Filter` correctly (not `Where-Object`)
3. Create an OU and a group for a new department
4. Bulk-provision users from a CSV
5. Log every action and every failure

---

## Exercise 1 — Install / import the AD module

On `LON-CL1` (Windows 11), if not already installed:

```powershell
Get-WindowsCapability -Online -Name Rsat.ActiveDirectory* |
    Add-WindowsCapability -Online
```

Import and sanity-check:

```powershell
Import-Module ActiveDirectory
Get-Command -Module ActiveDirectory | Measure-Object   # ~140+ cmdlets

Get-ADDomain | Select-Object Forest, DNSRoot, DomainMode, PDCEmulator
```

If `Get-ADDomain` errors, you're not joined to the domain or your credentials
don't have the required access.

---

## Exercise 2 — Read users

Simple get:

```powershell
Get-ADUser -Filter * | Select-Object -First 5 Name, SamAccountName, Enabled
```

By identity:

```powershell
Get-ADUser -Identity 'Administrator'
```

With more properties:

```powershell
Get-ADUser -Identity 'Administrator' -Properties *
Get-ADUser -Identity 'Administrator' -Properties MemberOf, LastLogonDate, PasswordLastSet |
    Format-List Name, SamAccountName, LastLogonDate, PasswordLastSet
```

> **Default property set is small.** Use `-Properties` to pull more.

---

## Exercise 3 — Filter, done right

```powershell
# WRONG — pulls every user, then filters client-side. Slow on large directories.
Get-ADUser -Filter * -Properties Department |
    Where-Object { $_.Department -eq 'Sales' }

# RIGHT — LDAP filter applied at the DC. Fast.
Get-ADUser -Filter "Department -eq 'Sales'" -Properties Department
```

Variables in `-Filter` need string interpolation and quotes:

```powershell
$dept = 'Sales'
Get-ADUser -Filter "Department -eq '$dept'" -Properties Department
```

Wildcards use `-like`:

```powershell
Get-ADUser -Filter "Name -like 'A*'"
```

---

## Exercise 4 — Build the target OU

We'll provision into an `OU=Sales` under `OU=Adatum` (adjust to your topology).

```powershell
$ouName = 'Sales'
$ouRoot = 'DC=adatum,DC=com'

$existing = Get-ADOrganizationalUnit `
    -Filter "Name -eq '$ouName'" `
    -SearchBase $ouRoot `
    -ErrorAction SilentlyContinue

if (-not $existing) {
    New-ADOrganizationalUnit -Name $ouName -Path $ouRoot -ProtectedFromAccidentalDeletion:$false
    Write-Host "Created OU=$ouName" -ForegroundColor Green
} else {
    Write-Host "OU=$ouName already exists" -ForegroundColor Yellow
}

$ouPath = "OU=$ouName,$ouRoot"
Get-ADOrganizationalUnit -Identity $ouPath
```

---

## Exercise 5 — Build the target group

```powershell
$groupName = 'Sales-All'

$existing = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue

if (-not $existing) {
    New-ADGroup -Name $groupName `
        -GroupScope Global `
        -GroupCategory Security `
        -Path $ouPath `
        -Description 'All Sales department members'
    Write-Host "Created group $groupName" -ForegroundColor Green
} else {
    Write-Host "Group $groupName already exists" -ForegroundColor Yellow
}
```

---

## Exercise 6 — The source CSV

Create a CSV on your Desktop. Save it as `newusers.csv`:

```powershell
@'
FirstName,LastName,JobTitle,Phone,InitialPassword
Anna,Schmidt,Account Manager,+49 203 555-0101,TempP@ss123!
Bruno,Meier,Inside Sales,+49 203 555-0102,TempP@ss123!
Clara,Fischer,Sales Engineer,+49 203 555-0103,TempP@ss123!
Dominik,Weber,Regional Lead,+49 203 555-0104,TempP@ss123!
Elena,Koch,Account Executive,+49 203 555-0105,TempP@ss123!
'@ | Set-Content "$HOME\Desktop\newusers.csv"

Import-Csv "$HOME\Desktop\newusers.csv" | Format-Table
```

---

## Exercise 7 — Provision users with a log

Paste the whole block and run it. It creates users, adds them to the
`Sales-All` group, and emits a `PSCustomObject` per attempt so you have a
log at the end.

```powershell
$ouName    = 'Sales'
$ouPath    = "OU=$ouName,DC=adatum,DC=com"
$groupName = 'Sales-All'
$domainUPN = 'adatum.com'

$users = Import-Csv "$HOME\Desktop\newusers.csv"

$log = foreach ($u in $users) {
    $sam = ($u.FirstName.Substring(0,1) + $u.LastName).ToLower()
    $upn = "$sam@$domainUPN"
    $display = "$($u.FirstName) $($u.LastName)"
    $securePwd = ConvertTo-SecureString $u.InitialPassword -AsPlainText -Force

    try {
        $newParams = @{
            Name                  = $display
            GivenName             = $u.FirstName
            Surname               = $u.LastName
            DisplayName           = $display
            SamAccountName        = $sam
            UserPrincipalName     = $upn
            Title                 = $u.JobTitle
            Department            = $ouName
            OfficePhone           = $u.Phone
            Path                  = $ouPath
            AccountPassword       = $securePwd
            ChangePasswordAtLogon = $true
            Enabled               = $true
            ErrorAction           = 'Stop'
        }

        New-ADUser @newParams
        Add-ADGroupMember -Identity $groupName -Members $sam -ErrorAction Stop

        [pscustomobject]@{
            Time   = Get-Date
            User   = $sam
            UPN    = $upn
            Group  = $groupName
            Status = 'Created'
            Error  = $null
        }
    }
    catch {
        [pscustomobject]@{
            Time   = Get-Date
            User   = $sam
            UPN    = $upn
            Group  = $groupName
            Status = 'Failed'
            Error  = $_.Exception.Message
        }
    }
}

$log | Format-Table Time, User, Status, Error -AutoSize
$log | Export-Csv "$HOME\Desktop\provisioning-log.csv" -NoTypeInformation
```

---

## Exercise 8 — Verify

```powershell
Get-ADUser -Filter "Department -eq 'Sales'" -SearchBase $ouPath |
    Select-Object Name, SamAccountName, Enabled

Get-ADGroupMember -Identity 'Sales-All' |
    Select-Object Name, SamAccountName
```

---

## Exercise 9 — Modify in bulk

Add a common office location:

```powershell
Get-ADUser -Filter "Department -eq 'Sales'" -SearchBase $ouPath |
    Set-ADUser -Office 'Duisburg HQ'
```

Verify:

```powershell
Get-ADUser -Filter "Department -eq 'Sales'" -SearchBase $ouPath -Properties Office |
    Select-Object Name, Office
```

---

## Exercise 10 — Clean-up (lab hygiene)

**Only run this at the end of the lab, or if your instructor says so.**

```powershell
# Remove the Sales users
Get-ADUser -Filter "Department -eq 'Sales'" -SearchBase $ouPath |
    Remove-ADUser -Confirm:$false

# Remove the group
Remove-ADGroup -Identity 'Sales-All' -Confirm:$false

# Remove the OU — first turn off delete protection if it was enabled
Set-ADOrganizationalUnit -Identity $ouPath -ProtectedFromAccidentalDeletion:$false
Remove-ADOrganizationalUnit -Identity $ouPath -Recursive -Confirm:$false
```

---

## Check yourself

1. Why is `Get-ADUser -Filter "Department -eq 'Sales'"` faster than filtering with `Where-Object`?
2. Where do you put a variable inside a `-Filter` expression?
3. What's the difference between `-Path` and `-SearchBase`?
4. What does `ChangePasswordAtLogon = $true` do?
5. How did we keep the script from aborting on a single bad row?

_(Answers: the filter runs on the DC as LDAP, not client-side / inside the double-quoted filter string, wrapped in single quotes: `"Department -eq '$dept'"` / `-Path` is where a new object goes, `-SearchBase` is where to start looking / forces the user to set a new password at first sign-in / `try/catch` around each iteration emits a failed-status row instead of throwing.)_

---

## Wrap-up

You just did what 90 % of "PowerShell for AD admins" jobs look like:
read a CSV, create users, group them, log the result. The shape of
this script scales to hundreds of users without changing a line.
Tomorrow: do the same thing in the cloud, with Graph.
