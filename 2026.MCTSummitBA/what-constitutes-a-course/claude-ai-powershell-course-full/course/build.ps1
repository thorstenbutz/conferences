<#
.SYNOPSIS
    Renders every MARP deck under ./decks to PPTX, PDF, and HTML.
.DESCRIPTION
    Thin wrapper around `marp-cli`. Requires Node.js 18+ and MARP CLI:

        npm install --save-dev @marp-team/marp-cli

    Then from the course root:

        .\build.ps1                       # PPTX + PDF + HTML for all decks
        .\build.ps1 -Format pptx          # only PPTX
        .\build.ps1 -Deck day1            # only day1-*.md
        .\build.ps1 -Watch                # watch mode (MARP re-renders on save)

.PARAMETER Format
    Which output formats to produce. Any subset of pptx, pdf, html. Default: all three.
.PARAMETER Deck
    Substring to match deck filenames. 'day1' matches 'day1-foundations.md'.
.PARAMETER OutputDir
    Where to write artefacts. Default: ./out
.PARAMETER Watch
    Run MARP in watch mode for HTML (fastest feedback loop while editing).
.EXAMPLE
    .\build.ps1
.EXAMPLE
    .\build.ps1 -Format pptx -Deck day3
.EXAMPLE
    .\build.ps1 -Watch
#>
[CmdletBinding()]
param(
    [ValidateSet('pptx', 'pdf', 'html')]
    [string[]] $Format = @('pptx', 'pdf', 'html'),

    [string]   $Deck      = '*',
    [string]   $OutputDir = './out',
    [switch]   $Watch
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------- #
#  Locate marp-cli                                                             #
# ---------------------------------------------------------------------------- #

$scriptRoot = $PSScriptRoot
Set-Location $scriptRoot

$marpCandidates = @(
    Join-Path $scriptRoot 'node_modules/.bin/marp.cmd'
    Join-Path $scriptRoot 'node_modules/.bin/marp'
    'marp'
    'marp.cmd'
)

$marp = $marpCandidates | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1

if (-not $marp) {
    Write-Error @'
MARP CLI not found. Install it locally with:

    npm install --save-dev @marp-team/marp-cli

or globally with:

    npm install -g @marp-team/marp-cli
'@
    exit 1
}

Write-Host "Using MARP at: $marp" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------- #
#  Gather decks                                                                #
# ---------------------------------------------------------------------------- #

$decks = Get-ChildItem -Path './decks' -Filter '*.md' |
    Where-Object { $Deck -eq '*' -or $_.BaseName -like "*$Deck*" }

if (-not $decks) {
    Write-Warning "No decks matched '$Deck' under ./decks"
    exit 1
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# ---------------------------------------------------------------------------- #
#  Watch mode — HTML only, MARP handles the loop                               #
# ---------------------------------------------------------------------------- #

if ($Watch) {
    Write-Host "Watching $($decks.Count) deck(s). Ctrl+C to stop." -ForegroundColor Green
    & $marp --watch --no-stdin --html --output $OutputDir $decks.FullName
    return
}

# ---------------------------------------------------------------------------- #
#  One-shot rendering                                                          #
# ---------------------------------------------------------------------------- #

$summary = foreach ($deckFile in $decks) {
    foreach ($fmt in $Format) {
        $outFile = Join-Path $OutputDir ($deckFile.BaseName + '.' + $fmt)
        Write-Host ("  [{0,-4}] {1}" -f $fmt.ToUpper(), $deckFile.Name) -ForegroundColor Cyan

        $args = @('--no-stdin', "--$fmt", $deckFile.FullName, '-o', $outFile)

        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $marp @args *>&1 | Where-Object { $_ -notmatch 'INFO|WARN' } | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        $sw.Stop()

        [pscustomobject]@{
            Deck    = $deckFile.Name
            Format  = $fmt.ToUpper()
            Output  = $outFile
            Size_KB = if (Test-Path $outFile) { [math]::Round((Get-Item $outFile).Length / 1KB, 1) } else { 'FAIL' }
            Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        }
    }
}

Write-Host ''
$summary | Format-Table -AutoSize
Write-Host "Done. Artefacts in: $OutputDir" -ForegroundColor Green
