# Dispatcher for the playermap apps (js / ts / py / php) across the supported server cores.
#
# Usage examples:
# azerothcore, javascript:
# .\playermap.ps1 acore js
#
# cmangos-tbc, python (the default language):
# .\playermap.ps1 cmangos-tbc
#
# mangoszero, typescript:
# .\playermap.ps1 mangoszero ts
#
# with named parameters:
# .\playermap.ps1 -Server cmangos -Lang php
#
# print the command instead of running it:
# .\playermap.ps1 acore js -ShowCmd
#
# help:
# .\playermap.ps1 help
# .\playermap.ps1 -h

param(
    [Parameter(Position = 0)]
    [string]$Server,

    [Parameter(Position = 1)]
    [string]$Lang = 'py',

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

# Normalized server name -> the aliases you may type for it. Single source of
# truth: both the help text and the normalization below read from this.
$ServerGroups = [ordered]@{
    'acore'       = @('acore', 'azerothcore')
    'tcore'       = @('tcore', 'trinitycore')
    'cmangos'     = @('cmangos', 'classic', 'cmangos-classic')
    'cmangos-tbc' = @('cmangos-tbc', 'mangos-tbc', 'tbc')
    'vmangos'     = @('vmangos', 'vanilla')
    'mangoszero'  = @('mangoszero', 'mangos0', 'mangos-zero', 'zero')
}

$Languages   = @('js', 'ts', 'py', 'php')
$DefaultLang = 'py'
$PhpServers  = @('acore', 'tcore')
$PhpPort     = 8000
$ScriptName  = if ($PSCommandPath) { Split-Path -Leaf $PSCommandPath } else { 'playermap.ps1' }

# Help asked for as a plain word rather than as the -Help switch
$HelpTokens  = @('help', '--help', '-h', '-help', '/help', '/?', '-?')

function Write-ServerList {
    Write-InfoAlt "Servers:"
    foreach ($name in $ServerGroups.Keys) {
        Write-Host ("  {0,-13}{1}" -f $name, ($ServerGroups[$name] -join ', '))
    }
}

function Show-Usage {
    Write-Info "$ScriptName - launch a playermap app for a WoW server core"
    Write-Host ""
    Write-InfoAlt "Usage:"
    Write-Host "  $ScriptName <server> [$($Languages -join '|')] [-ShowCmd]"
    Write-Host "  $ScriptName -Server <server> -Lang <lang>"
    Write-Host "  $ScriptName help | -h"
    Write-Host ""
    Write-ServerList
    Write-Host ""
    Write-InfoAlt "Languages:"
    $plainLangs = ($Languages | Where-Object { $_ -ne 'php' }) -join ', '
    Write-Host ("  {0,-13}{1}" -f $plainLangs, "(default: $DefaultLang)")
    Write-Host ("  {0,-13}{1}" -f 'php', "only for: $($PhpServers -join ', ')")
    Write-Host ""
    Write-InfoAlt "Options:"
    Write-Host "  -ShowCmd     print the command that would be run, then exit"
    Write-Host "  -h, help     show this help"
    Write-Host ""
    Write-InfoAlt "Examples:"
    Write-Host "  $ScriptName acore js"
    Write-Host "  $ScriptName cmangos-tbc"
    Write-Host "  $ScriptName mangoszero ts"
    Write-Host "  $ScriptName -Server cmangos -Lang php"
    Write-Host "  $ScriptName acore js -ShowCmd"
}

function Show-UsageAndExit ([string]$problem) {
    Write-Err $problem
    Write-Host ""
    Show-Usage
    exit 1
}

# -h / -Help, or 'help' / '--help' typed where the server goes
if ($Help -or ($Server -and $HelpTokens -contains $Server.ToLower())) {
    Show-Usage
    exit 0
}

# Anything the parameters above did not take is an argument we do not understand
if ($Rest -and $Rest.Count -gt 0) {
    Show-UsageAndExit ("Unknown argument(s): " + ($Rest -join ' '))
}

# No server given - show what is on offer before asking for one
if (-not $Server) {
    Write-ServerList
    Write-Host ""
    $Server = (Read-Host "Server").Trim()
    if (-not $Server) {
        Show-UsageAndExit "No server given."
    }
}

$normalized = $null
$wantedServer = $Server.ToLower()
foreach ($name in $ServerGroups.Keys) {
    if ($ServerGroups[$name] -contains $wantedServer) {
        $normalized = $name
        break
    }
}

if (-not $normalized) {
    Show-UsageAndExit "Unknown server '$Server'."
}

$Lang = $Lang.ToLower()
if ($Languages -notcontains $Lang) {
    Show-UsageAndExit "Unknown language '$Lang'."
}

if (-not $env:CODE_ROOT_DIR) {
    Write-Err "Environment variable CODE_ROOT_DIR is not defined. Exiting."
    exit 1
}

# Helper to build the path under Code2\Python\wander_nodes_util
function Get-MapPath {
    param($subdir)
    return Join-Path -Path $env:CODE_ROOT_DIR -ChildPath ("Code2\Python\wander_nodes_util\$subdir")
}

$jsTsPyDirs = @{
    'acore'      = @{ js='js_map';     ts='ts_map';     py='py_map';      pyScript='app.py' }
    'tcore'      = @{ js='js_map';     ts='ts_map';     py='py_map';      pyScript='app.py' }
    'cmangos'    = @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
    'cmangos-tbc'= @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
    'vmangos'    = @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
    'mangoszero' = @{ js='js_map_tbc'; ts='ts_map_tbc'; py='py_map';      pyScript='app_cmangos.py' }
}

# Work out where to run and what to run, so -ShowCmd can print it verbatim
if ($Lang -eq 'php') {
    if ($PhpServers -notcontains $normalized) {
        Show-UsageAndExit "PHP playermap is only supported for: $($PhpServers -join ', ')."
    }

    $fullPath = Get-MapPath ("${normalized}_map\playermap")
    $runExe   = 'php'
    $runArgs  = @('-S', "localhost:$PhpPort")
} else {
    if (-not $jsTsPyDirs.ContainsKey($normalized)) {
        # should never happen, but safe-guard
        Write-Err "Unexpected error: no configuration for server '$normalized'"
        exit 1
    }

    $config   = $jsTsPyDirs[$normalized]
    $fullPath = Get-MapPath $config[$Lang]

    switch ($Lang) {
        'js' { $runExe = 'npm';    $runArgs = @('run', 'dev') }
        'ts' { $runExe = 'npm';    $runArgs = @('run', 'dev:watch') }
        'py' { $runExe = 'python'; $runArgs = @($config['pyScript']) }
    }
}

$runCmd = "$runExe $($runArgs -join ' ')"

if ($ShowCmd) {
    if (-not (Test-Path $fullPath)) {
        Write-Warn "Note: directory does not exist: $fullPath"
    }

    Write-Info "Equivalent PowerShell command:"
    Write-Host "# $ScriptName $normalized $Lang"
    Write-Host "`$env:SELECTED_SERVER = '$normalized'"
    Write-Host "Set-Location '$fullPath'"
    Write-Host $runCmd
    exit 0
}

if (-not (Test-Path $fullPath)) {
    Write-Err "Directory not found: $fullPath"
    exit 1
}

# Export the selected server for downstream use
$env:SELECTED_SERVER = $normalized

Write-Ok "Launching $normalized playermap ($Lang) in $fullPath"
Write-Info "Running: $runCmd"
Set-Location $fullPath
& $runExe @runArgs
