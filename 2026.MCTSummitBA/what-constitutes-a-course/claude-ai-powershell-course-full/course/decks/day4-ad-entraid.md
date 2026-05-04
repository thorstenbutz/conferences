---
marp: true
theme: noble-blue
paginate: true
title: "Day 4 — AD On-Prem + EntraID via Graph"
---

<!-- _class: title -->

# PowerShell 7 for IT Administrators
## Day 4 — AD On-Prem + EntraID via Graph

---

## Today

- **Morning** — on-prem Active Directory with the RSAT `ActiveDirectory` module
- **Afternoon** — EntraID with the `Microsoft.Graph` PowerShell SDK
- **Capstone** — a hybrid AD/EntraID reconciliation report
- **Close** — best practices, next steps

---

<!-- _class: section -->

# Part 1
## Active Directory

---

## The AD module

Ships with **RSAT** (Remote Server Administration Tools):

```powershell
# On a client — install once
Get-WindowsCapability -Online -Name Rsat.ActiveDirectory* |
    Add-WindowsCapability -Online

# On a server — via Server Manager or:
Install-WindowsFeature RSAT-AD-PowerShell
```

Then:

```powershell
Import-Module ActiveDirectory
Get-Command -Module ActiveDirectory | Measure-Object   # ~140 cmdlets
```

---

## Reading users

```powershell
Get-ADUser -Identity 'aschmidt'
Get-ADUser -Filter * -SearchBase 'OU=Sales,DC=adatum,DC=com'
Get-ADUser -Filter "Department -eq 'Sales'" -Properties Department, Manager
```

Default property set is small. Use **`-Properties`** to pull more:

```powershell
Get-ADUser aschmidt -Properties *
```

---

<!-- _class: gotcha -->

## `-Filter` is not `Where-Object`

```powershell
# WRONG — runs Where-Object on ALL users in AD. Slow, memory-heavy.
Get-ADUser -Filter * | Where-Object Department -eq 'Sales'

# RIGHT — LDAP filter sent to the DC. Fast.
Get-ADUser -Filter "Department -eq 'Sales'"
```

`-Filter` uses a **pseudo-PowerShell** syntax that's converted to LDAP.
Quote the whole thing. Variables need `$()`:

```powershell
$dept = 'Sales'
Get-ADUser -Filter "Department -eq '$dept'"
```

---

## Creating users

```powershell
$pwd = ConvertTo-SecureString 'TempP@ss!' -AsPlainText -Force

$userParams = @{
    Name              = 'Anna Schmidt'
    SamAccountName    = 'aschmidt'
    GivenName         = 'Anna'
    Surname           = 'Schmidt'
    UserPrincipalName = 'aschmidt@adatum.com'
    Path              = 'OU=Sales,DC=adatum,DC=com'
    AccountPassword   = $pwd
    Enabled           = $true
    ChangePasswordAtLogon = $true
}
New-ADUser @userParams
```

---

## Bulk — CSV in, users out

`newusers.csv`:

```
FirstName,LastName,Department,JobTitle
Anna,Schmidt,Sales,Account Manager
Bob,Meier,Sales,Inside Sales
```

```powershell
Import-Csv .\newusers.csv | ForEach-Object {
    $sam = ($_.FirstName + $_.LastName).ToLower()
    $upn = "$sam@adatum.com"

    New-ADUser `
        -Name "$($_.FirstName) $($_.LastName)" `
        -SamAccountName $sam `
        -UserPrincipalName $upn `
        -GivenName $_.FirstName -Surname $_.LastName `
        -Department $_.Department -Title $_.JobTitle `
        -Path 'OU=Sales,DC=adatum,DC=com' `
        -AccountPassword $pwd -Enabled $true
}
```

---

## Groups and OUs

```powershell
# OU
New-ADOrganizationalUnit -Name 'Sales' -Path 'DC=adatum,DC=com'

# Group
New-ADGroup -Name 'Sales-All' -GroupScope Global -Path 'OU=Sales,DC=adatum,DC=com'

# Membership
Add-ADGroupMember -Identity 'Sales-All' -Members aschmidt, bmeier
Get-ADGroupMember -Identity 'Sales-All'
Remove-ADGroupMember -Identity 'Sales-All' -Members aschmidt -Confirm:$false
```

---

## Modifying users

```powershell
Set-ADUser aschmidt -Title 'Senior Account Manager' -Office 'Duisburg'

Disable-ADAccount aschmidt
Enable-ADAccount  aschmidt

Unlock-ADAccount  aschmidt

Set-ADAccountPassword aschmidt -Reset -NewPassword (
    ConvertTo-SecureString 'NewP@ss123!' -AsPlainText -Force
)
```

---

<!-- _class: section -->

# Part 2
## EntraID via Microsoft Graph

---

<!-- _class: history -->

## The Azure identity PowerShell history

- **MSOnline** (2013) — original "Azure AD v1" cmdlets (`Get-MsolUser`)
- **AzureAD** (2016) — v2 cmdlets (`Get-AzureADUser`)
- **AzureADPreview** — experimental features, never promoted fully
- Both MSOnline and AzureAD **retired March 30, 2024** — no new features, no new tenants
- **Microsoft.Graph PowerShell SDK** (2021+) — the official future

Today: use `Microsoft.Graph`. Nothing else.

---

## Graph, not a module — a family

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Get-Module Microsoft.Graph* -ListAvailable | Measure-Object
```

There are **~40 sub-modules**. Importing the whole umbrella is slow.
Import just what you need:

```powershell
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement
```

---

## Az and Graph — a brief note

- **`Az`** = Azure Resource Manager PowerShell (subscriptions, VMs, storage…)
- **`Microsoft.Graph`** = identity, M365, Teams, SharePoint, Intune

They're siblings, not rivals. `Az` uses Graph internally for some identity
operations (`Get-AzADUser` ≈ a Graph call). We'll stay on pure Graph today.

---

## Connecting

```powershell
Connect-MgGraph -Scopes 'User.Read.All', 'Group.Read.All'
```

A browser opens, you consent to the scopes, a token is cached. Then:

```powershell
Get-MgContext
Get-MgUser -Top 5
```

---

## Scopes matter

Graph uses **least-privilege** permissions. You only get what you asked for.

| Scope                           | Lets you                          |
|---------------------------------|-----------------------------------|
| `User.Read.All`                 | read all user properties          |
| `User.ReadWrite.All`            | create / modify / delete users    |
| `Group.Read.All`                | read all groups and memberships   |
| `Group.ReadWrite.All`           | manage groups                     |
| `Directory.Read.All`            | read directory-wide objects       |
| `Directory.AccessAsUser.All`    | act with the sign-in user's rights |

Ask only for what your script actually needs.

---

## Reading users

```powershell
Get-MgUser -UserId 'aschmidt@adatum.com'
Get-MgUser -Top 10

Get-MgUser -All -Filter "department eq 'Sales'" |
    Select-Object DisplayName, UserPrincipalName, Department
```

> **Gotcha:** Graph `-Filter` uses **OData syntax** — not PowerShell and
> not LDAP. Field names are **camelCase**, string literals in single quotes.

---

<!-- _class: gotcha -->

## Graph filter quirks

```powershell
# endswith / startswith need the ConsistencyLevel header
Get-MgUser -All `
    -Filter "endsWith(mail,'@adatum.com')" `
    -ConsistencyLevel eventual -CountVariable c

# booleans have no quotes
Get-MgUser -Filter 'accountEnabled eq true'

# dates are ISO 8601
Get-MgUser -Filter "createdDateTime ge 2025-01-01T00:00:00Z"
```

---

## Creating users

```powershell
$pwd = @{
    Password                      = 'TempP@ss123!'
    ForceChangePasswordNextSignIn = $true
}

$userBody = @{
    AccountEnabled    = $true
    DisplayName       = 'Anna Schmidt'
    MailNickname      = 'aschmidt'
    UserPrincipalName = 'aschmidt@yourtenant.onmicrosoft.com'
    PasswordProfile   = $pwd
    Department        = 'Sales'
    UsageLocation     = 'DE'
}

New-MgUser -BodyParameter $userBody
```

`UsageLocation` is required before licences can be assigned.

---

## Groups

```powershell
# Create a security group
New-MgGroup -DisplayName 'Sales-All' -MailEnabled:$false `
            -MailNickname 'Sales-All' -SecurityEnabled

# Add a member (note the odata.id ceremony — blame the API)
$user  = Get-MgUser  -UserId 'aschmidt@adatum.com'
$group = Get-MgGroup -Filter "displayName eq 'Sales-All'"

New-MgGroupMember -GroupId $group.Id `
    -DirectoryObjectId $user.Id
```

---

## Paging — don't forget `-All`

```powershell
# default page size is 100
Get-MgUser                          # first 100 only
Get-MgUser -All                     # follows @odata.nextLink for you
Get-MgUser -PageSize 999 -All       # tune for huge tenants
```

Forgetting `-All` is the **#1 Graph bug** in scripts. You get 100 rows
and wonder why your report is missing people.

---

<!-- _class: section -->

# Part 3
## Capstone — hybrid reconciliation

---

## The scenario

Your tenant is Entra-joined. The DC syncs users via Entra Connect.
Over time, accounts drift:

- user exists on-prem but not in EntraID
- user exists in EntraID but not on-prem (cloud-only, or orphaned)
- different display names for the same UPN

**Goal:** produce a CSV that lists every account with its status on both sides.

---

## Approach

1. `Get-ADUser -Filter *` → hashtable keyed by UPN
2. `Get-MgUser -All`       → hashtable keyed by UPN
3. Walk the union of keys, output a `PSCustomObject` per UPN with both sides
4. `Export-Csv` the result
5. Sanity-check in Excel

You'll build this in Lab 8.

---

<!-- _class: lab -->

# Lab 7
## AD bulk provisioning

**Goal:** From a CSV of new hires, create AD users, groups, OU membership,
and emit a success/failure log.

**Duration:** ~60 minutes

Open `labs/lab07-ad-bulk.md`.

---

<!-- _class: lab -->

# Lab 8
## Capstone — AD ↔ EntraID reconciliation

**Goal:** Combine every skill from all four days into one practical report.

**Duration:** ~90 minutes

Open `labs/lab08-capstone.md`.

---

<!-- _class: section -->

# Part 4
## Close

---

## Best practices you can take home Monday

- **One verb, one noun, one job.** If your script does three things, it's three scripts.
- **Use splatting** for anything beyond three parameters.
- **Emit objects, not text.** `PSCustomObject` everywhere.
- **`-ErrorAction Stop` + `try/catch`** for anything that writes state.
- **Source-control your scripts.** Git, even just local, costs nothing.
- **Test with `-WhatIf`** before running any destructive command.

---

## What you did not learn (yet)

This was foundations. The follow-on courses cover:

- **Advanced functions** — parameter sets, `ShouldProcess`, dynamic parameters, pipeline binding
- **Module authoring** — `.psm1`, `.psd1`, PSGallery publication
- **Testing** — Pester, mocking, code coverage
- **Linting & CI** — PSScriptAnalyzer, GitHub Actions
- **DSC** — desired-state configuration
- **AI-assisted PowerShell authoring** — GitHub Copilot, agentic IDEs

---

## Resources to keep handy

- [learn.microsoft.com/powershell](https://learn.microsoft.com/powershell) — official docs
- [github.com/PowerShell/PowerShell](https://github.com/PowerShell/PowerShell) — source, issues, releases
- [powershellgallery.com](https://www.powershellgallery.com) — modules
- [reddit.com/r/PowerShell](https://reddit.com/r/PowerShell) — surprisingly good community
- *Windows PowerShell in Action* — Bruce Payette's book, still the canon
- *PowerShell in a Month of Lunches* — Don Jones, the best beginner book

---

## Thank you

Four days. Eight labs. A lot of `Get-Member`.

You now know more PowerShell than roughly 80 % of the people who
list it on their CV. The remaining 20 % is all practice.

**Questions?**

---

<!-- _class: title -->

# End of course
## Go automate something
