#param(
#    [ValidateSet('wotlk','tbc','classic')]
#    [string]$version = 'wotlk'
#)
#
#switch ($version) {
#    'wotlk' {
#        $wowEnv      = 'wow_dir'
#        $addonSubDir = 'wotlk\WTF'
#    }
#    'tbc' {
#        $wowEnv      = 'wow_tbc_dir'
#        $addonSubDir = 'tbc\WTF'
#    }
#    'classic' {
#        $wowEnv      = 'wow_classic_dir'
#        $addonSubDir = 'classic\WTF'
#    }
#}

# usage via params:
# .\wow_wtf_update.ps1 -version tbc
# without params:
# .\wow_wtf_update.ps1 tbc
#
# benilla's / cenilla's own WTF files (benilla-config / cenilla-config) into wow_addons' classic
# Account folder, the reverse of 'wow_wtf_fix benilla'; benilla asks which checkout when several
# have a benilla-config (Enter = the last one benilla.ps1 used):
# .\wow_wtf_update.ps1 benilla
# .\wow_wtf_update.ps1 benilla dir=benilla-gfx account=CMANGOS
# .\wow_wtf_update.ps1 cenilla --debug      (prints the PowerShell commands instead of running them)

function Show-Usage {
    Write-Host @"
Copies the WoW install's WTF Account folder and Config.wtf (as <UserDomain>_Config.wtf) of that
version (`$env:wow_dir / `$env:wow_tbc_dir / `$env:wow_classic_dir) into wow_addons
(Code2\Wow\addons\wow_addons\<version>\WTF), replacing its Account folder.

With benilla / cenilla it instead copies that client's own WTF files (its benilla-config /
cenilla-config) into wow_addons' classic Account folder, the reverse of 'wow_wtf_fix benilla':
  - each <kind>\<Realm>-<Char> file into Account\<account>\<Realm>\<Char>\ (the realm and character
    names, flattened in the file names, are found in that Account folder, else the install's); bindings
    from the clients' real-format .wtf files
  - the account-wide files (macros, bindings, SavedVariables, cache.md5) into Config.wtf's realmName
    account, or account=<name>
  Every other file in the Account folder is kept; Config.wtf is not touched (the clients keep config.toml).
  benilla: `$env:BENILLA_HOME when set (cenilla reads it too), else dir=<checkout>, else the only
  Code2\Wow\tools\benilla* checkout with a benilla-config, else a menu (Enter = the last one used);
  cenilla: Code2\Wow\tools\cenilla\cenilla-config.

Usage: .\wow_wtf_update.ps1 [classic|tbc|wotlk]  (default: wotlk, case insensitive)
       .\wow_wtf_update.ps1 benilla|cenilla [dir=<checkout>] [account=<name>] [--debug]
       .\wow_wtf_update.ps1 help | --help | -h
"@
}
if ($args | Where-Object { "$_" -in @('help', '--help', '-h') }) {
    Show-Usage
    exit 0
}

# --- benilla / cenilla: the clients' own WTF files into wow_addons' classic Account folder ---

function Write-Info($text) { Write-Host $text -ForegroundColor Cyan }
function Write-Ok  ($text) { Write-Host $text -ForegroundColor Green }
function Write-Warn($text) { Write-Host $text -ForegroundColor Yellow }
function Write-Err ($text) { Write-Host $text -ForegroundColor Red }
function Write-Cmd ($text) { Write-Host $text -ForegroundColor Blue }

$CLIENT_NAMES = @('benilla', 'cenilla')
$CLIENT_VERSION = 'classic'
$VERSION_NAMES = @('classic', 'tbc', 'wotlk')
$DEBUG_TOKENS = @('--debug', '-debug', 'debug')
$ACCOUNT_ARG = 'account='
$DIR_ARG = 'dir='
$CLIENT_WOW_ENV = 'wow_classic_dir'
$TOOLS_ROOT = Join-Path $env:code_root_dir 'Code2\Wow\tools'
$ADDONS_WTF_DIR = Join-Path $env:code_root_dir "Code2\Wow\addons\wow_addons\$CLIENT_VERSION\WTF"
# A benilla checkout is a benilla* dir holding the client crate (benilla.ps1's rule)
$BENILLA_PATTERN = 'benilla*'
$BENILLA_PREFIX = 'benilla-'
$BENILLA_MANIFEST = 'crates\benilla\Cargo.toml'
$CENILLA_REPO_NAME = 'cenilla'
$STATE_DIR_NAMES = @{ 'benilla' = 'benilla-config'; 'cenilla' = 'cenilla-config' }
# Both clients take their state folder from it when it is set
$STATE_HOME_VAR = 'BENILLA_HOME'
# The checkout benilla.ps1 ran last (its menu's default)
$LAST_CHECKOUT_FILE = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'benilla\last-dir'
$WTF_DIR_NAME = 'WTF'
$ACCOUNT_DIR_NAME = 'Account'
$CONFIG_WTF = 'Config.wtf'
$REALM_NAME_PATTERN = '^\s*SET\s+realmName\s+"([^"]*)"'
$SAVED_VARIABLES_DIR = 'SavedVariables'
$SAVED_VARIABLES_EXT = '.lua'
$SAVED_DIR = 'saved'
# A per-character kind's folder in the state folder, its file extension there and its WTF file
$CHARACTER_KINDS = [ordered]@{
    'macros'       = @('.txt', 'macros-cache.txt')
    'layout'       = @('.txt', 'layout-cache.txt')
    'chat'         = @('.txt', 'chat-cache.txt')
    'camera'       = @('.txt', 'camera-settings.txt')
    'addon-state'  = @('.txt', 'AddOns.txt')
    'config-cache' = @('.wtf', 'config-cache.wtf')
    'bindings'     = @('.wtf', 'bindings-cache.wtf')
}
# The account-wide files of the state folder and their WTF file
$ACCOUNT_FILES = [ordered]@{
    'macros\account.txt'       = 'macros-cache.txt'
    'config-cache\account.wtf' = 'config-cache.wtf'
    'bindings\account.wtf'     = 'bindings-cache.wtf'
    'saved-variables.lua'      = 'SavedVariables.lua'
    'cache.md5'                = 'cache.md5'
}
# The base name of a kind's account-wide file, not a character's
$ACCOUNT_FILE_BASE = 'account'
# A character file's base name: <Realm>-<Char>, the names flattened to letters, digits and _
$CHARACTER_KEY_SEPARATOR = '-'
$UNKNOWN_TOKEN = 'unknown'
$script:DebugMode = $false
$script:Stats = @{ Files = 0; Characters = 0; Skipped = 0 }

function Format-Arg($text) { return "'" + ($text -replace "'", "''") + "'" }

function Invoke-Step($command, [scriptblock]$action) {
    # Runs the action, or prints the PowerShell command doing it in debug mode
    if ($script:DebugMode) { Write-Cmd $command } else { & $action }
}

function Get-FileToken($name) {
    # A realm / character name as the clients put it in a file name (local_state::file_token)
    $token = -join ($name.ToCharArray() | ForEach-Object { if ([char]::IsLetterOrDigit($_)) { $_ } else { '_' } })
    if ($token) { return $token }
    return $UNKNOWN_TOKEN
}

function Copy-WtfFile($source, $destination) {
    $parent = Split-Path -Path $destination -Parent
    Invoke-Step "New-Item -ItemType Directory -Force -Path $(Format-Arg $parent) | Out-Null; Copy-Item -LiteralPath $(Format-Arg $source) -Destination $(Format-Arg $destination) -Force" {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
    $script:Stats.Files++
}

function Copy-SavedVariables($sourceDir, $destinationDir) {
    # The addons' saved variables (<Addon>.lua)
    if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) { return }
    foreach ($file in Get-ChildItem -LiteralPath $sourceDir -File | Where-Object { $_.Extension -eq $SAVED_VARIABLES_EXT }) {
        Copy-WtfFile $file.FullName (Join-Path $destinationDir $file.Name)
    }
}

function Get-RealmIndex($accountRoots) {
    # token(realm) -> @{ Account; Realm; Characters = token(char) -> name } from the Account folders,
    # the first one that has a realm winning
    $index = @{}
    foreach ($root in $accountRoots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        foreach ($account in Get-ChildItem -LiteralPath $root -Directory) {
            foreach ($realm in Get-ChildItem -LiteralPath $account.FullName -Directory | Where-Object { $_.Name -ne $SAVED_VARIABLES_DIR }) {
                $token = Get-FileToken $realm.Name
                if ($index.ContainsKey($token)) { continue }
                $characters = @{}
                foreach ($character in Get-ChildItem -LiteralPath $realm.FullName -Directory) { $characters[(Get-FileToken $character.Name)] = $character.Name }
                $index[$token] = @{ Account = $account.Name; Realm = $realm.Name; Characters = $characters }
            }
        }
    }
    return $index
}

function Resolve-CharacterDir($key, $index, $accountRoot) {
    # A <Realm>-<Char> file key's character folder in the Account folder ($null: an unknown realm)
    $realmToken, $characterToken = $key -split $CHARACTER_KEY_SEPARATOR, 2
    if (-not $characterToken -or -not $index.ContainsKey($realmToken)) { return $null }
    $realm = $index[$realmToken]
    $character = $(if ($realm.Characters.ContainsKey($characterToken)) { $realm.Characters[$characterToken] } else { $characterToken })
    return Join-Path $accountRoot "$($realm.Account)\$($realm.Realm)\$character"
}

function Resolve-TargetAccount($accountRoots, $wtfDir, $requested) {
    # The account the account-wide files go into: account=<name>, else the one holding Config.wtf's
    # realmName realm, else the only one
    $accounts = @($accountRoots | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | ForEach-Object { Get-ChildItem -LiteralPath $_ -Directory } |
        Select-Object -ExpandProperty Name -Unique)
    if ($requested) {
        $match = @($accounts | Where-Object { $_ -eq $requested })
        if ($match.Count -eq 0) { Write-Err "No account $requested (accounts: $($accounts -join ', '))."; exit 1 }
        return $match[0]
    }
    $realm = $null
    $config = Join-Path $wtfDir $CONFIG_WTF
    if (Test-Path -LiteralPath $config -PathType Leaf) {
        $line = Select-String -LiteralPath $config -Pattern $REALM_NAME_PATTERN | Select-Object -First 1
        if ($line) { $realm = $line.Matches[0].Groups[1].Value }
    }
    if ($realm) {
        foreach ($root in $accountRoots) {
            if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
            $match = @(Get-ChildItem -LiteralPath $root -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName $realm) -PathType Container })
            if ($match.Count -gt 0) { return $match[0].Name }
        }
    }
    if ($accounts.Count -eq 1) { return $accounts[0] }
    Write-Err "No account holds $CONFIG_WTF's realmName realm ($realm) - pass account=<name> (accounts: $($accounts -join ', '))."
    exit 1
}

function Select-BenillaStateDir($requested) {
    # The benilla checkout's state folder to read: dir=<checkout> (its name, the name without
    # benilla-, or a path), else the only checkout with one, else a menu (Enter = the last used)
    $checkouts = @(Get-ChildItem -LiteralPath $TOOLS_ROOT -Directory -Filter $BENILLA_PATTERN -ErrorAction SilentlyContinue |
        Where-Object { (Test-Path -LiteralPath (Join-Path $_.FullName $BENILLA_MANIFEST) -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName $STATE_DIR_NAMES['benilla']) -PathType Container) } | Sort-Object Name)
    if ($requested) {
        if (Test-Path -LiteralPath $requested -PathType Container) { return Join-Path (Get-Item -LiteralPath $requested).FullName $STATE_DIR_NAMES['benilla'] }
        $match = @($checkouts | Where-Object { $_.Name -eq $requested -or $_.Name -eq "$BENILLA_PREFIX$requested" })
        if ($match.Count -eq 0) { Write-Err "No benilla checkout with a $($STATE_DIR_NAMES['benilla']) matches $requested (have: $(($checkouts | ForEach-Object { $_.Name }) -join ', '))."; exit 1 }
        return Join-Path $match[0].FullName $STATE_DIR_NAMES['benilla']
    }
    if ($checkouts.Count -eq 0) { Write-Err "No benilla checkout under $TOOLS_ROOT has a $($STATE_DIR_NAMES['benilla'])."; exit 1 }
    if ($checkouts.Count -eq 1) { return Join-Path $checkouts[0].FullName $STATE_DIR_NAMES['benilla'] }

    $last = $null
    try { if (Test-Path -LiteralPath $LAST_CHECKOUT_FILE -PathType Leaf) { $last = ([string](Get-Content -LiteralPath $LAST_CHECKOUT_FILE -TotalCount 1)).Trim() } } catch {}
    $default = $null
    Write-Info "benilla checkouts with a $($STATE_DIR_NAMES['benilla']) under ${TOOLS_ROOT}:"
    for ($i = 0; $i -lt $checkouts.Count; $i++) {
        $mark = ' '
        if ($last -and $checkouts[$i].FullName -eq $last) { $default = $i; $mark = '*' }
        $branch = git -C $checkouts[$i].FullName branch --show-current 2>$null
        Write-Host ("{0} {1}) {2,-22} {3}" -f $mark, ($i + 1), $checkouts[$i].Name, $branch)
    }
    if ([Console]::IsInputRedirected) { Write-Err "Several checkouts and no terminal to pick one - pass dir=<checkout>."; exit 1 }
    $prompt = "Read from which? (1-$($checkouts.Count)$(if ($null -ne $default) { ", Enter = $($checkouts[$default].Name)" }))"
    $answer = ([string](Read-Host $prompt)).Trim()
    if (-not $answer -and $null -ne $default) { return Join-Path $checkouts[$default].FullName $STATE_DIR_NAMES['benilla'] }
    $index = 0
    if ([int]::TryParse($answer, [ref]$index) -and $index -ge 1 -and $index -le $checkouts.Count) { return Join-Path $checkouts[$index - 1].FullName $STATE_DIR_NAMES['benilla'] }
    Write-Err "Not a checkout number: $answer"
    exit 1
}

function Copy-StateIntoAccount($stateDir, $accountRoot, $index, $mainAccount) {
    # Overlays the Account folder with the state folder's WTF files (see Show-Usage)
    $characters = @{}
    foreach ($kind in $CHARACTER_KINDS.Keys) {
        $ext, $wtfName = $CHARACTER_KINDS[$kind]
        $dir = Join-Path $stateDir $kind
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Extension -eq $ext -and $_.BaseName -ne $ACCOUNT_FILE_BASE }) {
            $target = Resolve-CharacterDir $file.BaseName $index $accountRoot
            if (-not $target) { Write-Warn "  no realm for $kind\$($file.Name) in the Account folders - skipped"; $script:Stats.Skipped++; continue }
            Copy-WtfFile $file.FullName (Join-Path $target $wtfName)
            $characters[$target] = $true
        }
    }
    $savedRoot = Join-Path $stateDir $SAVED_DIR
    if (Test-Path -LiteralPath $savedRoot -PathType Container) {
        foreach ($dir in Get-ChildItem -LiteralPath $savedRoot -Directory) {
            $target = Resolve-CharacterDir $dir.Name $index $accountRoot
            if (-not $target) { Write-Warn "  no realm for $SAVED_DIR\$($dir.Name) in the Account folders - skipped"; $script:Stats.Skipped++; continue }
            Copy-SavedVariables $dir.FullName (Join-Path $target $SAVED_VARIABLES_DIR)
            $characters[$target] = $true
        }
    }
    $script:Stats.Characters = $characters.Count

    $main = Join-Path $accountRoot $mainAccount
    foreach ($name in $ACCOUNT_FILES.Keys) {
        $source = Join-Path $stateDir $name
        if (Test-Path -LiteralPath $source -PathType Leaf) { Copy-WtfFile $source (Join-Path $main $ACCOUNT_FILES[$name]) }
    }
    Copy-SavedVariables $savedRoot (Join-Path $main $SAVED_VARIABLES_DIR)
}

$clients = @()
$requestedAccount = $null
$requestedDir = $null
$clientVersion = $null
$otherArgs = @()
foreach ($arg in $args) {
    $token = "$arg".ToLowerInvariant()
    if ($CLIENT_NAMES -contains $token) { if ($clients -notcontains $token) { $clients += $token } }
    elseif ($DEBUG_TOKENS -contains $token) { $script:DebugMode = $true }
    elseif ($token.StartsWith($ACCOUNT_ARG)) { $requestedAccount = "$arg".Substring($ACCOUNT_ARG.Length) }
    elseif ($token.StartsWith($DIR_ARG)) { $requestedDir = "$arg".Substring($DIR_ARG.Length) }
    elseif ($VERSION_NAMES -contains $token) { $clientVersion = $token }
    else { $otherArgs += "$arg" }
}
if ($clients.Count -gt 0) {
    if ($otherArgs.Count -gt 0) { Write-Err "Unknown arg: $($otherArgs -join ' ') - see '.\wow_wtf_update.ps1 help'."; exit 1 }
    if ($clients.Count -gt 1) { Write-Err "Name one client to copy from: benilla or cenilla."; exit 1 }
    if ($clientVersion -and $clientVersion -ne $CLIENT_VERSION) { Write-Err "benilla / cenilla are $CLIENT_VERSION (1.12.1) clients, not $clientVersion."; exit 1 }
    $client = $clients[0]
    if ($requestedDir -and $client -ne 'benilla') { Write-Warn "dir= picks a benilla checkout - ignoring it." }

    $homeDir = [Environment]::GetEnvironmentVariable($STATE_HOME_VAR)
    if ($homeDir) {
        Write-Info "`$env:$STATE_HOME_VAR is set - reading $homeDir."
        $stateDir = $homeDir
    } elseif ($client -eq 'benilla') {
        $stateDir = Select-BenillaStateDir $requestedDir
    } else {
        $stateDir = Join-Path $TOOLS_ROOT "$CENILLA_REPO_NAME\$($STATE_DIR_NAMES['cenilla'])"
    }
    if (-not (Test-Path -LiteralPath $stateDir -PathType Container)) { Write-Err "No $client state folder: $stateDir"; exit 1 }
    if (-not (Test-Path -LiteralPath $ADDONS_WTF_DIR -PathType Container)) { Write-Err "Destination directory not found: $ADDONS_WTF_DIR"; exit 1 }

    # The names come from the destination's Account folder, else the install's
    $accountRoot = Join-Path $ADDONS_WTF_DIR $ACCOUNT_DIR_NAME
    $wowRootEnv = [Environment]::GetEnvironmentVariable($CLIENT_WOW_ENV)
    $installWtf = $(if ($wowRootEnv) { Join-Path $wowRootEnv $WTF_DIR_NAME } else { $null })
    $accountRoots = @($accountRoot) + $(if ($installWtf) { @(Join-Path $installWtf $ACCOUNT_DIR_NAME) } else { @() })
    $index = Get-RealmIndex $accountRoots
    $mainAccount = Resolve-TargetAccount $accountRoots $(if ($installWtf) { $installWtf } else { $ADDONS_WTF_DIR }) $requestedAccount

    Write-Info "Copying $stateDir into $accountRoot (account-wide files into $mainAccount)$(if ($script:DebugMode) { ' - debug: printing the commands only' })"
    Copy-StateIntoAccount $stateDir $accountRoot $index $mainAccount
    Write-Ok "$($script:Stats.Characters) characters, $($script:Stats.Files) files$(if ($script:Stats.Skipped) { ", $($script:Stats.Skipped) skipped (unknown realm)" }); account-wide files into $mainAccount"
    if (-not $script:DebugMode) { Set-Location $ADDONS_WTF_DIR }
    Write-Ok "Done."
    exit 0
}

# Use args instead of param (to avoid specifying param key)
if ($args.Count -ge 1) {
    $ver = $args[0].ToLower()
} else {
    #$ver = 'classic'
    #$ver = 'tbc'
    $ver = 'wotlk'
}

switch ($ver) {
    'wotlk' {
        $wowEnv      = 'wow_dir'
        $addonSubDir = 'wotlk\WTF'
    }
    'tbc' {
        $wowEnv      = 'wow_tbc_dir'
        $addonSubDir = 'tbc\WTF'
    }
    'classic' {
        $wowEnv      = 'wow_classic_dir'
        $addonSubDir = 'classic\WTF'
    }
    default {
        Write-Host "ERROR: Unknown version '$ver'. Valid values are wotlk, tbc, classic." -ForegroundColor Red
        exit 1
    }
}

# Resolve the root paths
$wowRoot   = (Get-Item "env:$wowEnv").Value
$destRoot  = Join-Path $env:code_root_dir "Code2\Wow\addons\wow_addons\$addonSubDir"

# Ensure the WOW directory exists
if (-not (Test-Path $wowRoot)) {
    Write-Host "ERROR: Wow directory not found: $wowRoot" -ForegroundColor Red
    exit 1
}
Write-Host "Using ${wowEnv} ($ver): $wowRoot"

# Get and print the current UserDomain
$userDomain = $env:UserDomain
Write-Host "User Domain: $userDomain"

# Build source paths
$sourceWtfDir  = Join-Path $wowRoot 'WTF'
$sourceConfig  = Join-Path $sourceWtfDir 'Config.wtf'
$sourceAccount = Join-Path $sourceWtfDir 'Account'

# Ensure destination exists
if (-not (Test-Path $destRoot)) {
    Write-Host "ERROR: Destination directory not found: $destRoot" -ForegroundColor Red
    exit 1
}

# Copy Config.wtf with domain prefix
$destConfig = Join-Path $destRoot ("${userDomain}_Config.wtf")
if (-not (Test-Path $sourceConfig)) {
    Write-Host "ERROR: Source Config.wtf not found: $sourceConfig" -ForegroundColor Red
    exit 1
}
Copy-Item -Path $sourceConfig -Destination $destConfig -Force
Write-Host "Copied Config.wtf -> $destConfig"

# Replace the Account folder
$destAccount = Join-Path $destRoot 'Account'
if (Test-Path $sourceAccount) {
    if (Test-Path $destAccount) {
        Remove-Item -Path $destAccount -Recurse -Force
        Write-Host "Removed existing Account folder at $destAccount"
    }
    Copy-Item -Path $sourceAccount -Destination $destRoot -Recurse -Force
    Write-Host "Copied Account folder -> $destAccount"
}
else {
    Write-Host "WARNING: Source Account folder not found: $sourceAccount" -ForegroundColor Yellow
}

Set-Location $destRoot
# or:
cd $destRoot
Write-Host "Done."

