# Day 4 Cheat Sheet — AD + EntraID via Graph

## AD module (RSAT)

```powershell
Import-Module ActiveDirectory
Get-ADDomain | Select Forest, DNSRoot, DomainMode, PDCEmulator
```

## AD — read users

```powershell
Get-ADUser -Identity 'aschmidt'
Get-ADUser -Identity 'aschmidt' -Properties *
Get-ADUser -Filter * -SearchBase 'OU=Sales,DC=adatum,DC=com'
Get-ADUser -Filter "Department -eq 'Sales'" -Properties Department
```

**`-Filter` ≠ `Where-Object`.** Quote the whole filter. Variables go inside via
`"Department -eq '$dept'"`.

## AD — create / modify

```powershell
$p = @{
    Name              = 'Anna Schmidt'
    SamAccountName    = 'aschmidt'
    GivenName         = 'Anna' ; Surname = 'Schmidt'
    UserPrincipalName = 'aschmidt@adatum.com'
    Path              = 'OU=Sales,DC=adatum,DC=com'
    AccountPassword   = (ConvertTo-SecureString 'TempP@ss!' -AsPlainText -Force)
    Enabled           = $true
    ChangePasswordAtLogon = $true
}
New-ADUser @p

Set-ADUser aschmidt -Title 'Senior AM' -Office 'Duisburg'
Disable-ADAccount aschmidt
Enable-ADAccount  aschmidt
Unlock-ADAccount  aschmidt
```

## AD — OU & groups

```powershell
New-ADOrganizationalUnit -Name 'Sales' -Path 'DC=adatum,DC=com'
New-ADGroup -Name 'Sales-All' -GroupScope Global -GroupCategory Security `
            -Path 'OU=Sales,DC=adatum,DC=com'

Add-ADGroupMember    -Identity 'Sales-All' -Members aschmidt
Get-ADGroupMember    -Identity 'Sales-All'
Remove-ADGroupMember -Identity 'Sales-All' -Members aschmidt -Confirm:$false
```

## Bulk from CSV

```powershell
Import-Csv .\newusers.csv | ForEach-Object {
    $sam = ($_.FirstName + $_.LastName).ToLower()
    New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
               -SamAccountName $sam -UserPrincipalName "$sam@adatum.com" `
               -Path 'OU=Sales,DC=adatum,DC=com' `
               -AccountPassword $pwd -Enabled $true
}
```

## Microsoft Graph SDK

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
```

## Connect & context

```powershell
Connect-MgGraph -Scopes 'User.Read.All', 'Group.Read.All'
Get-MgContext
Disconnect-MgGraph
```

Common scopes (least-privilege!):

| Scope                          | Grants                               |
|--------------------------------|---------------------------------------|
| `User.Read.All`                | read all users                        |
| `User.ReadWrite.All`           | create / update / delete users        |
| `Group.Read.All`               | read groups & memberships             |
| `Group.ReadWrite.All`          | manage groups                         |
| `Directory.Read.All`           | read directory objects                |

## Read users

```powershell
Get-MgUser -Top 5
Get-MgUser -All -Property DisplayName, UserPrincipalName, Department
Get-MgUser -UserId 'aschmidt@adatum.com'
```

**Always use `-All`** — default page size is 100, no error if truncated.

## OData filters (Graph, **not** LDAP, **not** PowerShell)

```powershell
Get-MgUser -All -Filter "department eq 'Sales'"
Get-MgUser -All -Filter 'accountEnabled eq false'
Get-MgUser -All -Filter "createdDateTime ge 2025-01-01T00:00:00Z"

# startsWith / endsWith need ConsistencyLevel eventual
Get-MgUser -All -ConsistencyLevel eventual -CountVariable c `
    -Filter "endsWith(mail,'@adatum.com')"
```

Field names are **camelCase**. Strings in single quotes. Booleans unquoted.

## Create a user

```powershell
$body = @{
    AccountEnabled    = $true
    DisplayName       = 'Anna Schmidt'
    MailNickname      = 'aschmidt'
    UserPrincipalName = 'aschmidt@yourtenant.onmicrosoft.com'
    UsageLocation     = 'DE'
    PasswordProfile   = @{
        Password                      = 'TempP@ss123!'
        ForceChangePasswordNextSignIn = $true
    }
}
New-MgUser -BodyParameter $body
```

## Groups

```powershell
New-MgGroup -DisplayName 'Sales-All' -MailEnabled:$false `
            -MailNickname 'Sales-All' -SecurityEnabled

$u = Get-MgUser  -UserId 'aschmidt@...'
$g = Get-MgGroup -Filter "displayName eq 'Sales-All'"
New-MgGroupMember -GroupId $g.Id -DirectoryObjectId $u.Id
Get-MgGroupMember -GroupId $g.Id -All
```

## Az vs Graph (FYI)

- `Az` = **Azure Resource Manager** — subscriptions, VMs, storage.
- `Microsoft.Graph` = **identity & M365** — users, groups, Intune, Teams.
- `Az.Resources` uses Graph under the hood for identity operations.
- Use `Az` for subscription-level work; use Graph for everything else in this course.

## Reconciliation pattern (AD ↔ Graph)

```powershell
$adByUpn    = @{} ; Get-ADUser -Filter * -Properties UserPrincipalName |
    ForEach-Object { if ($_.UserPrincipalName) { $adByUpn[$_.UserPrincipalName.ToLower()] = $_ } }

$cldByUpn   = @{} ; Get-MgUser -All -Property DisplayName, UserPrincipalName, AccountEnabled |
    ForEach-Object { if ($_.UserPrincipalName) { $cldByUpn[$_.UserPrincipalName.ToLower()] = $_ } }

$allUpns = @($adByUpn.Keys) + @($cldByUpn.Keys) | Sort-Object -Unique

foreach ($upn in $allUpns) {
    $ad  = $adByUpn[$upn] ; $cld = $cldByUpn[$upn]
    [pscustomobject]@{
        UPN    = $upn
        Status = switch ($true) {
            ($null -ne $ad -and $null -ne $cld) { 'InBoth';    break }
            ($null -ne $ad)                     { 'OnPremOnly'; break }
            default                             { 'CloudOnly' }
        }
    }
}
```
