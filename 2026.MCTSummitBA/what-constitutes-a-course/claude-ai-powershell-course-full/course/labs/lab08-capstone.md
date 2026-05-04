# Lab 8 — Capstone: AD ↔ EntraID reconciliation

**Duration:** ~90 minutes
**Target machine:** `LON-CL1`
**Prerequisites:** Labs 1–7 complete, Microsoft.Graph PowerShell SDK installable, EntraID free tenant with Global Reader or better

---

## Goals

Combine everything you've learned over four days into one real report:

1. Install and connect to Microsoft Graph with least-privilege scopes
2. Pull users from both **on-prem AD** and **EntraID**
3. Match them on UPN, find mismatches
4. Emit a reconciliation CSV
5. Do it cleanly, with error handling, verbose output, and PSCustomObject rows

---

## Exercise 1 — Install the Graph SDK

```powershell
Get-Module Microsoft.Graph -ListAvailable
```

If the module list is empty:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

The metapackage installs ~40 sub-modules — takes a couple of minutes.
For this lab we only need a handful:

```powershell
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement
```

Verify:

```powershell
Get-Command -Module Microsoft.Graph.Users | Measure-Object
```

---

## Exercise 2 — Connect to Graph

Ask only for the scopes you need. For a read-only reconciliation report:

```powershell
Connect-MgGraph -Scopes 'User.Read.All', 'Directory.Read.All'
```

A browser window opens, you sign in, and (for the first use) you consent to
the scopes. After that:

```powershell
Get-MgContext
```

You should see your tenant ID, account, and the exact scopes you asked for.

---

## Exercise 3 — Read users from Graph

```powershell
Get-MgUser -Top 5 | Select-Object DisplayName, UserPrincipalName, Id
```

Get everyone (mind the page size):

```powershell
$cloudUsers = Get-MgUser -All -Property DisplayName, UserPrincipalName, AccountEnabled, Department, Id
$cloudUsers.Count
$cloudUsers | Select-Object -First 5 DisplayName, UserPrincipalName, Department, AccountEnabled
```

> **Gotcha:** without `-All`, you get the first 100 users and no error. That
> single flag is the #1 Graph gotcha.

---

## Exercise 4 — OData filtering

Graph filters are **OData**, not LDAP and not PowerShell:

```powershell
# equality
Get-MgUser -All -Filter "department eq 'Sales'" -Property DisplayName, Department

# startsWith / endsWith need the eventual-consistency header
Get-MgUser -All `
    -Filter "endsWith(mail,'@adatum.com')" `
    -ConsistencyLevel eventual -CountVariable c `
    -Property Mail, DisplayName

# booleans are unquoted
Get-MgUser -All -Filter 'accountEnabled eq false' -Property DisplayName

# dates are ISO 8601
Get-MgUser -All -Filter "createdDateTime ge 2025-01-01T00:00:00Z" -Property CreatedDateTime, DisplayName
```

---

## Exercise 5 — Read users from on-prem AD

Using yesterday's skills. Pull everything you need in one call:

```powershell
Import-Module ActiveDirectory

$adUsers = Get-ADUser -Filter * `
    -Properties DisplayName, UserPrincipalName, Department, Enabled |
    Select-Object DisplayName, UserPrincipalName, Department,
        @{ N = 'Enabled'; E = { $_.Enabled } },
        SamAccountName

$adUsers.Count
$adUsers | Select-Object -First 5
```

---

## Exercise 6 — Build lookup tables

Hashtables, keyed on UPN (lowercased for safety):

```powershell
$adByUpn = @{}
foreach ($u in $adUsers) {
    if ($u.UserPrincipalName) {
        $adByUpn[$u.UserPrincipalName.ToLower()] = $u
    }
}

$cloudByUpn = @{}
foreach ($u in $cloudUsers) {
    if ($u.UserPrincipalName) {
        $cloudByUpn[$u.UserPrincipalName.ToLower()] = $u
    }
}

$adByUpn.Count
$cloudByUpn.Count
```

---

## Exercise 7 — Reconcile

Walk the union of keys and emit one row per UPN:

```powershell
$allUpns = @($adByUpn.Keys) + @($cloudByUpn.Keys) | Sort-Object -Unique

$report = foreach ($upn in $allUpns) {
    $ad    = $adByUpn[$upn]
    $cloud = $cloudByUpn[$upn]

    $status = switch ($true) {
        ($null -ne $ad -and  $null -ne $cloud) { 'InBoth'     ; break }
        ($null -ne $ad -and  $null -eq $cloud) { 'OnPremOnly' ; break }
        ($null -eq $ad -and  $null -ne $cloud) { 'CloudOnly'  ; break }
        default                                { 'Unknown' }
    }

    [pscustomobject]@{
        UPN            = $upn
        Status         = $status
        AD_Name        = $ad.DisplayName
        AD_Enabled     = if ($null -ne $ad) { [bool]$ad.Enabled } else { $null }
        AD_Department  = $ad.Department
        Cloud_Name     = $cloud.DisplayName
        Cloud_Enabled  = $cloud.AccountEnabled
        Cloud_Dept     = $cloud.Department
        NameMismatch   = ($ad -and $cloud -and ($ad.DisplayName -ne $cloud.DisplayName))
        DeptMismatch   = ($ad -and $cloud -and ($ad.Department  -ne $cloud.Department))
    }
}

$report | Group-Object Status | Select-Object Name, Count
```

---

## Exercise 8 — Export and eyeball

```powershell
$outPath = "$HOME\Desktop\ad-entraid-reconciliation.csv"

$report |
    Sort-Object Status, UPN |
    Export-Csv -Path $outPath -NoTypeInformation -Encoding UTF8

Write-Host "Report written to $outPath"
Invoke-Item $outPath      # opens in Excel (or your default CSV app)
```

Sanity-check in the shell:

```powershell
$report | Where-Object Status -eq 'OnPremOnly' | Select-Object -First 5 UPN, AD_Name
$report | Where-Object Status -eq 'CloudOnly'  | Select-Object -First 5 UPN, Cloud_Name
$report | Where-Object NameMismatch            | Select-Object -First 5 UPN, AD_Name, Cloud_Name
```

---

## Exercise 9 — Bonus: group membership in Graph

A taste of what's possible for a follow-on report:

```powershell
$group = Get-MgGroup -Filter "displayName eq 'Sales-All'" -ErrorAction SilentlyContinue

if ($group) {
    Get-MgGroupMember -GroupId $group.Id -All |
        ForEach-Object {
            Get-MgUser -UserId $_.Id -Property DisplayName, UserPrincipalName |
                Select-Object DisplayName, UserPrincipalName
        }
} else {
    Write-Warning "Group 'Sales-All' not found in this tenant."
}
```

---

## Exercise 10 — Disconnect cleanly

```powershell
Disconnect-MgGraph
Get-MgContext       # should now be $null
```

---

## The finished script (optional wrap-up)

If you want, combine the work into a single `.ps1`. Save as
`$HOME\Desktop\Invoke-Reconciliation.ps1`:

```powershell
<#
.SYNOPSIS
    Compares on-prem AD users to EntraID users on UPN.
.EXAMPLE
    .\Invoke-Reconciliation.ps1 -OutputPath C:\Reports\recon.csv
#>
param(
    [string] $OutputPath = "$HOME\Desktop\ad-entraid-reconciliation.csv"
)

# Load modules
Import-Module ActiveDirectory        -ErrorAction Stop
Import-Module Microsoft.Graph.Users  -ErrorAction Stop

# Connect (no-op if already connected with these scopes)
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'User.Read.All', 'Directory.Read.All' | Out-Null
}

Write-Verbose 'Pulling AD users...'
$adUsers = Get-ADUser -Filter * -Properties DisplayName, UserPrincipalName, Department, Enabled

Write-Verbose 'Pulling EntraID users...'
$cloudUsers = Get-MgUser -All -Property DisplayName, UserPrincipalName, AccountEnabled, Department, Id

# Build lookups
$adByUpn    = @{}; foreach ($u in $adUsers)    { if ($u.UserPrincipalName) { $adByUpn[$u.UserPrincipalName.ToLower()]    = $u } }
$cloudByUpn = @{}; foreach ($u in $cloudUsers) { if ($u.UserPrincipalName) { $cloudByUpn[$u.UserPrincipalName.ToLower()] = $u } }

$allUpns = @($adByUpn.Keys) + @($cloudByUpn.Keys) | Sort-Object -Unique

$report = foreach ($upn in $allUpns) {
    $ad    = $adByUpn[$upn]
    $cloud = $cloudByUpn[$upn]

    $status = switch ($true) {
        ($null -ne $ad -and  $null -ne $cloud) { 'InBoth'     ; break }
        ($null -ne $ad -and  $null -eq $cloud) { 'OnPremOnly' ; break }
        ($null -eq $ad -and  $null -ne $cloud) { 'CloudOnly'  ; break }
        default                                { 'Unknown' }
    }

    [pscustomobject]@{
        UPN           = $upn
        Status        = $status
        AD_Name       = $ad.DisplayName
        AD_Enabled    = if ($null -ne $ad) { [bool]$ad.Enabled } else { $null }
        AD_Department = $ad.Department
        Cloud_Name    = $cloud.DisplayName
        Cloud_Enabled = $cloud.AccountEnabled
        Cloud_Dept    = $cloud.Department
        NameMismatch  = ($ad -and $cloud -and ($ad.DisplayName -ne $cloud.DisplayName))
        DeptMismatch  = ($ad -and $cloud -and ($ad.Department  -ne $cloud.Department))
    }
}

$report | Sort-Object Status, UPN |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Report: $OutputPath"
$report | Group-Object Status | Select-Object Name, Count
```

Run it:

```powershell
.\Invoke-Reconciliation.ps1 -Verbose
```

---

## Check yourself

1. Which Graph flag is the most common cause of incomplete reports?
2. What's the difference between LDAP `-Filter` and Graph `-Filter` syntax?
3. Why did we lowercase UPNs before using them as hashtable keys?
4. Name three Graph scopes and what they grant.
5. What does `Disconnect-MgGraph` actually do — invalidate the token, or just clear the local cache?

_(Answers: the missing `-All` — default is 100 rows / LDAP is a Microsoft pseudo-syntax translated to LDAP; Graph uses OData with camelCase fields, single-quoted string literals, and unquoted booleans / case-insensitive match in one place / e.g. `User.Read.All` = read all users, `Group.Read.All` = read groups, `Directory.ReadWrite.All` = full directory write / clears the local session cache; the token on the server side expires on its own schedule.)_

---

## Wrap-up

**Congratulations — you've completed the course.**

Over four days you've gone from `Get-Date` to building a cross-cloud identity
reconciliation tool. Every piece is something you'll actually use: the
pipeline, providers, CIM, parameters, error handling, remoting, AD, Graph.

What's next for you:

- Add this script to a Git repo and sign it into source control
- Wrap it in Task Scheduler to run weekly
- The follow-on course picks up with **advanced functions**, Pester testing,
  module authoring, and CI-tested scripts

Thank you for four days of `F8`.
