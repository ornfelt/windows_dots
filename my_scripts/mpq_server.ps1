# Dispatcher for the mpq file server (py / js) across the extracted mpq dirs of each expansion.
# Before launching it brings the chosen mpq dir up to date: the server scripts and index.html are
# copied from {my_notes_path}/scripts/wow/file_server when they differ, any legacy cors_server.js/py
# is removed, and exp.txt is created if missing (an exp.txt with the wrong value is an error).
#
# Usage examples:
# wotlk, python (both defaults):
# .\mpq_server.ps1
#
# tbc, python:
# .\mpq_server.ps1 tbc
#
# classic, javascript:
# .\mpq_server.ps1 classic js
#
# wotlk, javascript (expansion and language may come in any order):
# .\mpq_server.ps1 js
#
# with named parameters:
# .\mpq_server.ps1 -Expansion tbc -Lang js
#
# print the commands instead of running them:
# .\mpq_server.ps1 tbc js -ShowCmd
#
# help:
# .\mpq_server.ps1 help
# .\mpq_server.ps1 -h

param(
    [Parameter(Position = 0)]
    [string]$Expansion,

    [Parameter(Position = 1)]
    [string]$Lang,

    [Alias('h', '?')]
    [switch]$Help,

    [switch]$ShowCmd,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

function Write-Ok     ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err    ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn   ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info   ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt([string]$m) { Write-Host $m -ForegroundColor Magenta }

# Normalized expansion name -> the env var holding its mpq dir and the aliases
# you may type for it. Single source of truth for the help text and lookups.
$ExpGroups = [ordered]@{
    'wotlk'   = @{ EnvVar = 'wow_mpq_dir';         Aliases = @('wotlk', 'wrath') }
    'tbc'     = @{ EnvVar = 'wow_tbc_mpq_dir';     Aliases = @('tbc', 'bc') }
    'classic' = @{ EnvVar = 'wow_classic_mpq_dir'; Aliases = @('classic', 'vanilla') }
}

$Languages     = @('py', 'js')
$DefaultExp    = 'wotlk'
$DefaultLang   = 'py'
$ServerName    = 'mpq_server'
$ExpFile       = 'exp.txt'
$SourceSubdir  = 'scripts\wow\file_server'
$SyncFiles     = @("$ServerName.py", "$ServerName.js", 'index.html')
$LegacyFiles   = @('cors_server.py', 'cors_server.js')
$ScriptName    = if ($PSCommandPath) { Split-Path -Leaf $PSCommandPath } else { 'mpq_server.ps1' }

# Help asked for as a plain word rather than as the -Help switch
$HelpTokens  = @('help', '--help', '-h', '-help', '/help', '/?', '-?')

function Write-ExpansionList {
    Write-InfoAlt "Expansions:"
    foreach ($name in $ExpGroups.Keys) {
        Write-Host ("  {0,-9}{1,-26}{2}" -f $name, "`$env:$($ExpGroups[$name].EnvVar)", ($ExpGroups[$name].Aliases -join ', '))
    }
}

function Show-Usage {
    Write-Info "$ScriptName - sync and launch the mpq file server for a WoW expansion"
    Write-Host ""
    Write-InfoAlt "Usage:"
    Write-Host "  $ScriptName [expansion] [$($Languages -join '|')] [-ShowCmd]"
    Write-Host "  $ScriptName -Expansion <expansion> -Lang <lang>"
    Write-Host "  $ScriptName help | -h"
    Write-Host ""
    Write-ExpansionList
    Write-Host ("  {0,-9}{1}" -f '', "(default: $DefaultExp)")
    Write-Host ""
    Write-InfoAlt "Languages:"
    Write-Host ("  {0,-9}{1}" -f ($Languages -join ', '), "(default: $DefaultLang)")
    Write-Host ""
    Write-InfoAlt "Synced from `$env:my_notes_path\$($SourceSubdir):"
    Write-Host "  $($SyncFiles -join ', ')"
    Write-Host ""
    Write-InfoAlt "Options:"
    Write-Host "  -ShowCmd     print the commands that would be run, then exit"
    Write-Host "  -h, help     show this help"
    Write-Host ""
    Write-InfoAlt "Examples:"
    Write-Host "  $ScriptName"
    Write-Host "  $ScriptName tbc"
    Write-Host "  $ScriptName classic js"
    Write-Host "  $ScriptName js"
    Write-Host "  $ScriptName -Expansion tbc -Lang js"
    Write-Host "  $ScriptName tbc js -ShowCmd"
}

function Show-UsageAndExit ([string]$problem) {
    Write-Err $problem
    Write-Host ""
    Show-Usage
    exit 1
}

function Get-ExpansionName ([string]$wanted) {
    $wanted = $wanted.ToLower()
    foreach ($name in $ExpGroups.Keys) {
        if ($ExpGroups[$name].Aliases -contains $wanted) {
            return $name
        }
    }
    return $null
}

$tokens = @($Expansion, $Lang) | Where-Object { $_ }

# -h / -Help, or 'help' / '--help' typed where an argument goes
if ($Help -or ($tokens | Where-Object { $HelpTokens -contains $_.ToLower() })) {
    Show-Usage
    exit 0
}

# Anything the parameters above did not take is an argument we do not understand
if ($Rest -and $Rest.Count -gt 0) {
    Show-UsageAndExit ("Unknown argument(s): " + ($Rest -join ' '))
}

# Expansion and language may come in either order, so sort the tokens by what they are
$exp      = $null
$langName = $null
foreach ($token in $tokens) {
    $lower = $token.ToLower()
    if ($Languages -contains $lower) {
        if ($langName) { Show-UsageAndExit "Language given twice: '$langName' and '$lower'." }
        $langName = $lower
        continue
    }

    $found = Get-ExpansionName $token
    if (-not $found) { Show-UsageAndExit "Unknown argument '$token'." }
    if ($exp) { Show-UsageAndExit "Expansion given twice: '$exp' and '$found'." }
    $exp = $found
}

if (-not $exp)      { $exp = $DefaultExp }
if (-not $langName) { $langName = $DefaultLang }
$envVar = $ExpGroups[$exp].EnvVar

if (-not $env:my_notes_path) {
    Write-Err "Environment variable 'my_notes_path' is not set. Exiting."
    exit 1
}
$sourceDir = Join-Path $env:my_notes_path $SourceSubdir

$mpqDir = [System.Environment]::GetEnvironmentVariable($envVar)
if ([string]::IsNullOrEmpty($mpqDir)) {
    Write-Err "Environment variable '$envVar' ($exp mpq dir) is not set. Exiting."
    exit 1
}
if (-not (Test-Path -Path $mpqDir -PathType Container)) {
    Write-Err "Directory '$mpqDir' (from env variable '$envVar') does not exist. Exiting."
    exit 1
}

# Work out what needs doing first, so -ShowCmd can print it instead of doing it
$toCopy = @()
foreach ($file in $SyncFiles) {
    $src = Join-Path $sourceDir $file
    $dst = Join-Path $mpqDir $file
    if (-not (Test-Path -Path $src -PathType Leaf)) {
        Write-Err "Source file not found: $src"
        exit 1
    }
    if (-not (Test-Path -Path $dst -PathType Leaf) -or
        (Get-FileHash -Path $src).Hash -ne (Get-FileHash -Path $dst).Hash) {
        $toCopy += $file
    }
}

$toRemove = @($LegacyFiles | Where-Object { Test-Path -Path (Join-Path $mpqDir $_) })

$expPath   = Join-Path $mpqDir $ExpFile
$createExp = $true
if (Test-Path -Path $expPath -PathType Leaf) {
    # Trimmed, so a trailing newline (CRLF or LF) still matches
    $foundExp = "$(Get-Content -Path $expPath -Raw)".Trim()
    if ($foundExp) {
        if ($foundExp -ne $exp) {
            Write-Err "'$expPath' says '$foundExp', expected '$exp'."
            Write-Err "Check that env variable '$envVar' points at the $exp mpq dir. Exiting."
            exit 1
        }
        $createExp = $false
    }
}

switch ($langName) {
    'py' { $runExe = 'python'; $runArgs = @("$ServerName.py") }
    'js' { $runExe = 'node';   $runArgs = @("$ServerName.js") }
}
$runCmd = "$runExe $($runArgs -join ' ')"

if ($ShowCmd) {
    Write-Info "Equivalent PowerShell command:"
    Write-Host "# $ScriptName $exp $langName"
    foreach ($file in $toCopy) {
        Write-Host "Copy-Item -Force '$(Join-Path $sourceDir $file)' '$(Join-Path $mpqDir $file)'"
    }
    foreach ($file in $toRemove) {
        Write-Host "Remove-Item -Force '$(Join-Path $mpqDir $file)'"
    }
    if ($createExp) {
        Write-Host "Set-Content -Path '$expPath' -Value '$exp'"
    }
    Write-Host "Set-Location '$mpqDir'"
    Write-Host $runCmd
    exit 0
}

Write-Info "Syncing $exp mpq dir: $mpqDir"

foreach ($file in $SyncFiles) {
    if ($toCopy -notcontains $file) {
        Write-Ok "  up to date: $file"
        continue
    }
    $dst   = Join-Path $mpqDir $file
    $state = if (Test-Path -Path $dst -PathType Leaf) { 'updated' } else { 'copied' }
    try {
        Copy-Item -Path (Join-Path $sourceDir $file) -Destination $dst -Force -ErrorAction Stop
    } catch {
        Write-Err "Failed to copy $($file): $_. Exiting."
        exit 1
    }
    Write-Warn "  $($state): $file"
}

foreach ($file in $toRemove) {
    try {
        Remove-Item -Path (Join-Path $mpqDir $file) -Force -ErrorAction Stop
    } catch {
        Write-Err "Failed to remove $($file): $_. Exiting."
        exit 1
    }
    Write-Warn "  removed legacy: $file"
}

if ($createExp) {
    try {
        Set-Content -Path $expPath -Value $exp -ErrorAction Stop
    } catch {
        Write-Err "Failed to write $($expPath): $_. Exiting."
        exit 1
    }
    Write-Warn "  created: $ExpFile ($exp)"
} else {
    Write-Ok "  $ExpFile ok: $exp"
}

if (-not (Test-Path -Path (Join-Path $mpqDir 'file_paths.txt') -PathType Leaf)) {
    Write-Warn "Note: 'file_paths.txt' does not exist in '$mpqDir'. Run print_files.ps1 to generate it."
}
if ($langName -eq 'js' -and -not (Test-Path -Path (Join-Path $mpqDir 'node_modules') -PathType Container)) {
    Write-Warn "Note: 'node_modules' does not exist in '$mpqDir'. Run 'npm install express cors' there."
}

Write-Ok "Launching $exp $ServerName ($langName) in $mpqDir"
Write-Info "Running: $runCmd"
Set-Location $mpqDir
& $runExe @runArgs
