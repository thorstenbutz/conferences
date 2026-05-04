<#
.SYNOPSIS
    Replaces the default lab domain (adatum.com) across the course labs and decks.

.DESCRIPTION
    The course ships with the standard AZ-040 lab topology — adatum.com / LON-DC1 /
    LON-CL1. Most classrooms need to change at least the DNS domain to match their
    own training infrastructure. This script does that safely:

      - only touches .md files under labs/, decks/, cheatsheets/
      - dry-run by default (no changes unless -Apply is given)
      - creates a timestamped backup folder before writing
      - prints a diff-style summary

.PARAMETER NewDnsDomain
    New AD DNS domain. Example: contoso.com
.PARAMETER NewNetBios
    Optional new NetBIOS domain for the "Adatum\Administrator" style strings.
    Defaults to the first label of NewDnsDomain capitalised.
.PARAMETER NewDomainController
    Optional new DC hostname (default: LON-DC1 stays).
.PARAMETER NewClient
    Optional new client hostname (default: LON-CL1 stays).
.PARAMETER OldDnsDomain
    Domain to replace. Default: adatum.com
.PARAMETER OldNetBios
    NetBIOS to replace. Default: Adatum
.PARAMETER Path
    Course root. Default: script's own folder.
.PARAMETER Apply
    Without this switch, runs as a preview (dry-run). With it, rewrites files.

.EXAMPLE
    .\Invoke-DomainSwap.ps1 -NewDnsDomain 'contoso.com'                  # preview
.EXAMPLE
    .\Invoke-DomainSwap.ps1 -NewDnsDomain 'contoso.com' -Apply           # do it
.EXAMPLE
    .\Invoke-DomainSwap.ps1 -NewDnsDomain 'corp.local' -NewNetBios 'CORP' `
                            -NewDomainController 'DC01' -NewClient 'WS01' -Apply
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9\-]*(\.[A-Za-z0-9\-]+)+$')]
    [string] $NewDnsDomain,

    [string] $NewNetBios,
    [string] $NewDomainController,
    [string] $NewClient,

    [string] $OldDnsDomain = 'adatum.com',
    [string] $OldNetBios   = 'Adatum',

    [string] $Path   = $PSScriptRoot,
    [switch] $Apply
)

$ErrorActionPreference = 'Stop'

if (-not $NewNetBios) {
    $NewNetBios = ($NewDnsDomain -split '\.')[0]
    $NewNetBios = $NewNetBios.Substring(0,1).ToUpper() + $NewNetBios.Substring(1).ToLower()
}

# ---------------------------------------------------------------------------- #
#  Build the replacement map                                                   #
# ---------------------------------------------------------------------------- #

$dc     = ($OldDnsDomain -split '\.' | ForEach-Object { "DC=$_" }) -join ','
$newDc  = ($NewDnsDomain -split '\.' | ForEach-Object { "DC=$_" }) -join ','

$replacements = [ordered]@{
    # LDAP distinguished name: DC=adatum,DC=com → DC=<...>
    $dc              = $newDc

    # DNS domain       adatum.com → newdns
    $OldDnsDomain    = $NewDnsDomain

    # NetBIOS domain   Adatum\     → <NewNetBios>\
    ("$OldNetBios\") = ("$NewNetBios\")

    # NetBIOS domain   Adatum      → <NewNetBios>    (standalone, word-boundary)
    # Handled below with a regex; see post-processing step.
}

if ($NewDomainController) { $replacements['LON-DC1'] = $NewDomainController }
if ($NewClient)           { $replacements['LON-CL1'] = $NewClient }

# ---------------------------------------------------------------------------- #
#  Target files                                                                #
# ---------------------------------------------------------------------------- #

$targets = @(
    Get-ChildItem -Path (Join-Path $Path 'labs')        -Filter '*.md' -EA 0
    Get-ChildItem -Path (Join-Path $Path 'decks')       -Filter '*.md' -EA 0
    Get-ChildItem -Path (Join-Path $Path 'cheatsheets') -Filter '*.md' -EA 0
    Get-ChildItem -Path $Path -Filter 'README.md'       -EA 0
)

if (-not $targets) {
    Write-Error "No .md files found under $Path"
    return
}

Write-Host "Mode:        $(if ($Apply) { 'APPLY' } else { 'DRY-RUN (use -Apply to write)' })"
Write-Host "Old domain:  $OldDnsDomain ($OldNetBios)"
Write-Host "New domain:  $NewDnsDomain ($NewNetBios)"
Write-Host "Files:       $($targets.Count)"
Write-Host ''

# ---------------------------------------------------------------------------- #
#  Backup                                                                      #
# ---------------------------------------------------------------------------- #

$backupRoot = $null
if ($Apply) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupRoot = Join-Path $Path ".backup-$stamp"
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Write-Host "Backup:      $backupRoot" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------- #
#  Process                                                                     #
# ---------------------------------------------------------------------------- #

$netbiosWordBoundary = [regex]("\b" + [regex]::Escape($OldNetBios) + "\b")

$summary = foreach ($file in $targets) {
    $text = Get-Content -Path $file.FullName -Raw
    $orig = $text

    foreach ($kv in $replacements.GetEnumerator()) {
        if ($kv.Key -and $kv.Value) {
            $text = $text.Replace($kv.Key, $kv.Value)
        }
    }

    # Standalone "Adatum" word → NewNetBios (after the backslash form already ran)
    $text = $netbiosWordBoundary.Replace($text, $NewNetBios)

    $changes = if ($text -eq $orig) { 0 } else {
        # Rough change count = number of replacement tokens now present that weren't before
        ($replacements.Values | Measure-Object).Count
    }

    if ($text -ne $orig) {
        if ($Apply) {
            $relPath = $file.FullName.Substring($Path.Length).TrimStart('\','/')
            $backup = Join-Path $backupRoot $relPath
            New-Item -ItemType Directory -Path (Split-Path $backup -Parent) -Force | Out-Null
            Copy-Item $file.FullName $backup
            $text | Set-Content -Path $file.FullName -NoNewline -Encoding UTF8
        }

        [pscustomobject]@{
            File    = $file.FullName.Substring($Path.Length).TrimStart('\','/')
            Changed = $true
        }
    } else {
        [pscustomobject]@{
            File    = $file.FullName.Substring($Path.Length).TrimStart('\','/')
            Changed = $false
        }
    }
}

$summary | Format-Table -AutoSize

$changed = @($summary | Where-Object Changed).Count
Write-Host ''
Write-Host "$changed of $($summary.Count) files would be modified."
if ($Apply) {
    Write-Host "Rollback: delete edited files, then:  Copy-Item -Recurse '$backupRoot\*' ." -ForegroundColor DarkGray
} else {
    Write-Host "Re-run with -Apply to actually rewrite the files." -ForegroundColor Yellow
}
