<#
.SYNOPSIS
    Validates that a student's machine is ready for the PowerShell course.

.DESCRIPTION
    Runs a series of non-destructive checks and prints a traffic-light report:

        [ OK ]   ready
        [WARN]   works but sub-optimal (e.g. PS 5.1 only, old help)
        [FAIL]   will block at least one lab

    Exits with code 0 if everything is OK or WARN, 1 if any FAIL.

    Safe to run any time. Does not install anything unless you pass -Fix,
    in which case it will try to install PowerShell 7 and VSCode extensions
    non-interactively via winget.

.PARAMETER Fix
    Try to remediate common misses (install PS 7 via winget, install missing
    VSCode extensions, update help).

.PARAMETER SkipAd
    Skip the Active Directory RSAT / domain checks (for students joining
    only the cloud portion of the course).

.EXAMPLE
    .\Test-LabEnvironment.ps1
.EXAMPLE
    .\Test-LabEnvironment.ps1 -Fix
#>
[CmdletBinding()]
param(
    [switch] $Fix,
    [switch] $SkipAd
)

# ---------------------------------------------------------------------------- #
#  Utilities                                                                   #
# ---------------------------------------------------------------------------- #

$script:results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [ValidateSet('OK','WARN','FAIL','INFO')][string]$Level,
        [string]$Check,
        [string]$Message,
        [string]$Fix = ''
    )
    $script:results.Add([pscustomobject]@{
        Level   = $Level
        Check   = $Check
        Message = $Message
        Fix     = $Fix
    })

    $colour = switch ($Level) {
        'OK'   { 'Green'   }
        'WARN' { 'Yellow'  }
        'FAIL' { 'Red'     }
        'INFO' { 'DarkGray' }
    }
    Write-Host ("  [{0,-4}] {1,-38} {2}" -f $Level, $Check, $Message) -ForegroundColor $colour
}

function Test-Cmd {
    param([string] $Name)
    [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------- #
#  Banner                                                                      #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'PowerShell 7 for IT Administrators — pre-flight check' -ForegroundColor Cyan
Write-Host ('=' * 60) -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------------------- #
#  1. PowerShell versions                                                      #
# ---------------------------------------------------------------------------- #

Write-Host 'PowerShell' -ForegroundColor White

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Add-Result OK 'Current host'  "PS $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
} else {
    Add-Result WARN 'Current host' "You are running PS $($PSVersionTable.PSVersion). Day 2+ expects PS 7."  `
        'Install PowerShell 7 (see below).'
}

$pwshAvailable = Test-Cmd 'pwsh'
if ($pwshAvailable) {
    $pwshVer = (& pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
    Add-Result OK 'pwsh installed' "pwsh $pwshVer"
} else {
    Add-Result FAIL 'pwsh installed' 'pwsh.exe not found in PATH.' `
        'winget install --id Microsoft.PowerShell --source winget'

    if ($Fix -and (Test-Cmd winget)) {
        Write-Host '  → attempting to install PowerShell 7 via winget...' -ForegroundColor DarkYellow
        winget install --id Microsoft.PowerShell --source winget -e --silent
    }
}

if (Test-Cmd 'powershell') {
    $wpsVer = (& powershell -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
    Add-Result INFO 'Windows PowerShell' "5.1 coexists: $wpsVer"
}

# ---------------------------------------------------------------------------- #
#  2. Execution policy                                                         #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'Execution policy' -ForegroundColor White

$policy = Get-ExecutionPolicy -Scope CurrentUser
switch ($policy) {
    'Undefined'  { Add-Result WARN 'CurrentUser policy' "Undefined (falls back to machine policy)" `
                    'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser' }
    'Restricted' { Add-Result FAIL 'CurrentUser policy' "Restricted — scripts will not run" `
                    'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser' }
    default      { Add-Result OK   'CurrentUser policy' $policy }
}

# ---------------------------------------------------------------------------- #
#  3. VSCode + extension                                                       #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'VSCode' -ForegroundColor White

$code = Get-Command code, code-insiders -ErrorAction SilentlyContinue | Select-Object -First 1
if ($code) {
    $ver = (& $code.Name --version 2>$null | Select-Object -First 1)
    Add-Result OK 'VSCode' "Found: $ver"

    $exts = & $code.Name --list-extensions 2>$null
    if ($exts -contains 'ms-vscode.powershell' -or $exts -contains 'ms-vscode.PowerShell') {
        Add-Result OK 'PowerShell extension' 'ms-vscode.powershell installed'
    } else {
        Add-Result WARN 'PowerShell extension' 'Missing — F8 integration will not work' `
            'code --install-extension ms-vscode.powershell'
        if ($Fix) {
            Write-Host '  → installing VSCode PowerShell extension...' -ForegroundColor DarkYellow
            & $code.Name --install-extension ms-vscode.powershell
        }
    }
} else {
    Add-Result FAIL 'VSCode' 'code.exe not in PATH' `
        'winget install --id Microsoft.VisualStudioCode --source winget'
}

# ---------------------------------------------------------------------------- #
#  4. Help content                                                             #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'Help content' -ForegroundColor White

try {
    $h = Get-Help Get-Service -ErrorAction Stop
    if ($h.Synopsis -and $h.Synopsis -notmatch 'not available') {
        Add-Result OK 'Updateable help' 'Installed'
    } else {
        Add-Result WARN 'Updateable help' 'Placeholder help only' 'Update-Help -Force'
    }
} catch {
    Add-Result WARN 'Updateable help' 'Could not query help' 'Update-Help -Force'
}

# ---------------------------------------------------------------------------- #
#  5. PSReadLine                                                               #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'PSReadLine' -ForegroundColor White

$prl = Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($prl) {
    if ($prl.Version -ge [version]'2.2.0') {
        Add-Result OK 'PSReadLine' "$($prl.Version) (history-based completion supported)"
    } else {
        Add-Result WARN 'PSReadLine' "$($prl.Version) (upgrade for better prediction)" `
            'Install-Module PSReadLine -Force -SkipPublisherCheck'
    }
} else {
    Add-Result WARN 'PSReadLine' 'Not installed'
}

# ---------------------------------------------------------------------------- #
#  6. Active Directory (RSAT)                                                  #
# ---------------------------------------------------------------------------- #

if (-not $SkipAd) {
    Write-Host ''
    Write-Host 'Active Directory (Day 4)' -ForegroundColor White

    $adModule = Get-Module -ListAvailable ActiveDirectory
    if ($adModule) {
        Add-Result OK 'ActiveDirectory module' "$($adModule[0].Version)"
    } else {
        $rsat = Get-WindowsCapability -Online -Name 'Rsat.ActiveDirectory*' -ErrorAction SilentlyContinue
        if ($rsat -and $rsat.State -eq 'Installed') {
            Add-Result WARN 'ActiveDirectory module' 'RSAT present but module not loaded' `
                'Import-Module ActiveDirectory'
        } else {
            Add-Result WARN 'ActiveDirectory module' 'RSAT not installed (needed for Day 4 labs 7, 8)' `
                'Get-WindowsCapability -Online -Name Rsat.ActiveDirectory* | Add-WindowsCapability -Online'
        }
    }

    # Domain join — not strictly required but useful to know
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($cs.PartOfDomain) {
        Add-Result OK 'Domain join' "Joined to $($cs.Domain)"
    } else {
        Add-Result INFO 'Domain join' 'Workgroup (fine for labs 1-6; AD labs need classroom domain)'
    }
}

# ---------------------------------------------------------------------------- #
#  7. Microsoft Graph SDK                                                      #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'Microsoft Graph SDK (Day 4)' -ForegroundColor White

$mg = Get-Module -ListAvailable Microsoft.Graph.Users
if ($mg) {
    $latest = $mg | Sort-Object Version -Descending | Select-Object -First 1
    Add-Result OK 'Microsoft.Graph.Users' "$($latest.Version)"
} else {
    Add-Result WARN 'Microsoft.Graph SDK' 'Not installed yet (Lab 8 will install it)' `
        'Install-Module Microsoft.Graph -Scope CurrentUser'
    if ($Fix) {
        Write-Host '  → installing Microsoft.Graph (this takes a minute)...' -ForegroundColor DarkYellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
}

# ---------------------------------------------------------------------------- #
#  8. Internet egress                                                          #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host 'Network' -ForegroundColor White

$targets = @(
    @{ Name = 'PowerShell Gallery';   Host = 'www.powershellgallery.com'; Port = 443 }
    @{ Name = 'GitHub';               Host = 'github.com';                Port = 443 }
    @{ Name = 'Microsoft Learn';      Host = 'learn.microsoft.com';       Port = 443 }
    @{ Name = 'Microsoft Graph';      Host = 'graph.microsoft.com';       Port = 443 }
)

foreach ($t in $targets) {
    $ok = Test-NetConnection -ComputerName $t.Host -Port $t.Port `
            -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($ok) { Add-Result OK $t.Name "$($t.Host):$($t.Port) reachable" }
    else     { Add-Result WARN $t.Name "$($t.Host):$($t.Port) unreachable (proxy? offline?)" }
}

# ---------------------------------------------------------------------------- #
#  Summary                                                                     #
# ---------------------------------------------------------------------------- #

Write-Host ''
Write-Host ('=' * 60) -ForegroundColor Cyan
$counts = $script:results | Group-Object Level | Select-Object Name, Count
$counts | Format-Table -AutoSize

$fails = @($script:results | Where-Object Level -eq 'FAIL').Count
$warns = @($script:results | Where-Object Level -eq 'WARN').Count

if ($fails -gt 0) {
    Write-Host "$fails blocking issue(s). Run with -Fix to auto-remediate common cases." -ForegroundColor Red
    exit 1
} elseif ($warns -gt 0) {
    Write-Host "$warns warning(s). Course will run but address them for best experience." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host 'All green — you are ready for Day 1.' -ForegroundColor Green
    exit 0
}
