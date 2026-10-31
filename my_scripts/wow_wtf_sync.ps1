# Syncs one account's WTF files into the other accounts of the same install (one account per
# server), keeping each target's own realm folder name.
#
# Usage:
# .\wow_wtf_sync.ps1                          # classic: VMANGOS -> CMANGOS, MANGOSZERO
# .\wow_wtf_sync.ps1 classic                  # the same
# .\wow_wtf_sync.ps1 classic mangoszero       # MANGOSZERO -> VMANGOS, CMANGOS
# .\wow_wtf_sync.ps1 classic --from cmangos --to vmangos
# .\wow_wtf_sync.ps1 wotlk                    # ACORE -> TCORE
# .\wow_wtf_sync.ps1 wotlk tcore              # TCORE -> ACORE
# .\wow_wtf_sync.ps1 classic --wow-dir D:\games\wow_classic   # another install (or as positional dir)
# .\wow_wtf_sync.ps1 classic --debug          # print the equivalent PowerShell commands, change nothing
#
# Names are case insensitive: vmangos / vm, cmangos / cm, mangoszero / zero / mz, acore / ac /
# azerothcore, tcore / tc / trinitycore (or the account folder's own name).
#
# Each target account folder is emptied, then gets the source's account files (macros, bindings,
# SavedVariables, ...) and the source's realm folder under the target's own realm name (CMANGOS
# keeps "MaNGOS", MANGOSZERO "MaNGOS Zero Server #1", ...). Any other realm folder in the source
# (an old realm name) is skipped. The source is not changed.

function Show-Usage {
    $lines = Get-Content -LiteralPath $PSCommandPath
    $start = [array]::IndexOf($lines, '# Usage:')
    $end = [array]::IndexOf($lines, '# (an old realm name) is skipped. The source is not changed.')
    $lines[$start..$end] | ForEach-Object { $_ -replace '^# ?', '' } | Write-Host
}

function Write-Info([string]$msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host $msg -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "WARNING: $msg" -ForegroundColor Yellow }
function Write-Err([string]$msg) { Write-Host "ERROR: $msg" -ForegroundColor Red }
function Write-Faint([string]$msg) { Write-Host $msg -ForegroundColor DarkGray }

# ---- arguments

$ver = ''
$from = ''
$to = ''
$wowRoot = ''
$debugRun = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]
    $lower = $arg.ToLower()
    if ($lower -in @('help', '--help', '-h')) { Show-Usage; exit 0 }
    elseif ($lower -in @('-f', '--from', '-from')) { $from = [string]$args[++$i] }
    elseif ($lower -in @('-t', '--to', '-to')) { $to = [string]$args[++$i] }
    elseif ($lower -in @('-d', '--wow-dir', '-wowdir')) { $wowRoot = [string]$args[++$i] }
    elseif ($lower -in @('--debug', '-debug', '--dry-run')) { $debugRun = $true }
    elseif ($lower.StartsWith('-')) { Write-Err "Unknown option '$arg'"; Show-Usage; exit 1 }
    elseif (-not $ver -and $lower -in @('classic', 'vanilla', 'wotlk')) { $ver = $lower }
    elseif (-not $wowRoot -and (Test-Path -LiteralPath $arg -PathType Container)) { $wowRoot = $arg }
    elseif (-not $from) { $from = $arg }
    else { Write-Err "Unexpected argument '$arg'"; Show-Usage; exit 1 }
}
if (-not $ver -or $ver -eq 'vanilla') { $ver = 'classic' }

# ---- accounts per install: account folder -> realm folder

switch ($ver) {
    'classic' {
        $wowEnv = 'wow_classic_dir'
        $accounts = @('VMANGOS', 'CMANGOS', 'MANGOSZERO')
        $realm = @{ VMANGOS = 'vmangos'; CMANGOS = 'MaNGOS'; MANGOSZERO = 'MaNGOS Zero Server #1' }
        $defaultFrom = 'VMANGOS'
    }
    'wotlk' {
        $wowEnv = 'wow_dir'
        $accounts = @('ACORE', 'TCORE')
        $realm = @{ ACORE = 'AzerothCore'; TCORE = 'Trinity' }
        $defaultFrom = 'ACORE'
    }
}

# An account name as given (alias or folder name, any case) -> the account key, or $null.
function Get-Account([string]$name) {
    switch ($name.ToLower()) {
        { $_ -in @('vmangos', 'vm') } { return 'VMANGOS' }
        { $_ -in @('cmangos', 'cm', 'mangos-classic') } { return 'CMANGOS' }
        { $_ -in @('mangoszero', 'zero', 'mz', 'mangos-zero') } { return 'MANGOSZERO' }
        { $_ -in @('acore', 'ac', 'azerothcore') } { return 'ACORE' }
        { $_ -in @('tcore', 'tc', 'trinitycore', 'trinity') } { return 'TCORE' }
    }
    return $null
}

if (-not $from) { $from = $defaultFrom }
$src = Get-Account $from
if (-not $src -or -not $realm.ContainsKey($src)) { Write-Err "Unknown $ver account '$from' ($($accounts -join ' '))"; exit 1 }

$targets = @()
if ($to) {
    foreach ($t in ($to -split ',')) {
        $acct = Get-Account $t.Trim()
        if (-not $acct -or -not $realm.ContainsKey($acct)) { Write-Err "Unknown $ver account '$t' ($($accounts -join ' '))"; exit 1 }
        if ($acct -eq $src) { Write-Err "'$t' is the source account"; exit 1 }
        $targets += $acct
    }
} else {
    $targets = @($accounts | Where-Object { $_ -ne $src })
}

# ---- paths

if (-not $wowRoot) {
    $wowRoot = [Environment]::GetEnvironmentVariable($wowEnv)
    if (-not $wowRoot) { Write-Err "Environment variable '$wowEnv' not set (or give --wow-dir)"; exit 1 }
}
$accountRoot = Join-Path $wowRoot 'WTF\Account'
if (-not (Test-Path -LiteralPath $accountRoot -PathType Container)) { Write-Err "Account directory not found: $accountRoot"; exit 1 }

# A folder under a parent, matched case insensitively; $null when there is none.
function Find-Dir([string]$parent, [string]$name) {
    Get-ChildItem -LiteralPath $parent -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $name } | Select-Object -First 1 -ExpandProperty FullName
}

$srcDir = Find-Dir $accountRoot $src
if (-not $srcDir) { Write-Err "Source account folder not found: $(Join-Path $accountRoot $src)"; exit 1 }
$srcRealm = Find-Dir $srcDir $realm[$src]
if (-not $srcRealm) { Write-Err "Source realm folder not found: $(Join-Path $srcDir $realm[$src])"; exit 1 }

$running = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path.StartsWith($wowRoot, [StringComparison]::OrdinalIgnoreCase) }
if ($running) {
    Write-Warn "a client of $wowRoot is running: it writes its WTF files at logout and exit, over what is synced now"
}

# A PowerShell string literal.
function Q([string]$s) { "'" + ($s -replace "'", "''") + "'" }

# Runs an action, or with --debug prints the PowerShell line it stands for.
function Invoke-Step([string]$line, [scriptblock]$action) {
    if ($debugRun) { Write-Host $line } else { & $action }
}

Write-Info "Install: $wowRoot ($ver)"
Write-Info "From:    $src (realm '$($realm[$src])'): $srcDir"
if ($debugRun) { Write-Faint "--debug: the commands are printed, nothing is changed" }

# ---- sync

foreach ($tgt in $targets) {
    $tgtDir = Find-Dir $accountRoot $tgt
    if (-not $tgtDir) { $tgtDir = Join-Path $accountRoot $tgt }
    $tgtRealm = $realm[$tgt]
    Write-Host ''
    Write-Info "== $src -> $tgt (realm '$tgtRealm'): $tgtDir"
    Invoke-Step "New-Item -ItemType Directory -Force -Path $(Q $tgtDir) | Out-Null" {
        New-Item -ItemType Directory -Force -Path $tgtDir | Out-Null
    }
    # empty the target, hidden files included
    Invoke-Step "Get-ChildItem -LiteralPath $(Q $tgtDir) -Force | Remove-Item -Recurse -Force" {
        Get-ChildItem -LiteralPath $tgtDir -Force | Remove-Item -Recurse -Force
    }

    foreach ($entry in Get-ChildItem -LiteralPath $srcDir -Force) {
        $path = $entry.FullName
        if ($entry.PSIsContainer -and $path -ne $srcRealm -and $entry.Name -ne 'SavedVariables') {
            Write-Warn "skipped '$($entry.Name)' in ${src}: not its realm '$($realm[$src])' (an old realm folder?)"
            continue
        }
        if ($path -eq $srcRealm) {
            $dest = Join-Path $tgtDir $tgtRealm
            Invoke-Step "Copy-Item -LiteralPath $(Q $path) -Destination $(Q $dest) -Recurse -Force" {
                Copy-Item -LiteralPath $path -Destination $dest -Recurse -Force
            }
            Write-Ok "  realm '$($realm[$src])' -> '$tgtRealm'"
        } else {
            Invoke-Step "Copy-Item -LiteralPath $(Q $path) -Destination $(Q $tgtDir) -Recurse -Force" {
                Copy-Item -LiteralPath $path -Destination $tgtDir -Recurse -Force
            }
            Write-Faint "  $($entry.Name)"
        }
    }
}

Write-Host ''
Write-Ok "Done: $src -> $($targets -join ' ')"
