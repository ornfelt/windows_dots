# Basically the same as wow_wtf_update but it copies 
# in the other direction: from the repo to local wow dir.
# Usage:
# .\wow_wtf_fix.ps1 classic
# .\wow_wtf_fix.ps1 tbc
# .\wow_wtf_fix.ps1 wotlk
#
# Copy the classic install's WTF into benilla's / cenilla's own state folder (benilla-config /
# cenilla-config), replacing their WTF files; benilla asks which checkouts when there are several
# (Enter = all). The account-wide files come from Config.wtf's realmName account unless named:
# .\wow_wtf_fix.ps1 benilla
# .\wow_wtf_fix.ps1 cenilla
# .\wow_wtf_fix.ps1 benilla cenilla account=CMANGOS
# Print the PowerShell commands instead of running them:
# .\wow_wtf_fix.ps1 benilla --debug

function Show-Usage {
    Write-Host @"
Copies the WTF Account folder of wow_addons (Code2\Wow\addons\wow_addons\<version>\WTF\Account)
into the WoW install of that version (`$env:wow_dir / `$env:wow_tbc_dir / `$env:wow_classic_dir),
replacing the install's Account folder.

With benilla / cenilla it instead copies the classic install's WTF (`$env:wow_classic_dir\WTF\Account)
into those clients' own state folder, replacing its WTF files (macros, bindings, layout, chat,
camera, addon-state, saved, saved-variables.lua, config-cache, cache.md5, wtf-import; config.toml,
cache\, AddOns\, Diagnostics\ and shots.txt are kept):
  - every account's characters: <file> -> <kind>\<Realm>-<Char>.txt (bindings converted to the clients' diff too)
  - the account-wide files (macros, bindings, SavedVariables, cache.md5) of one account: Config.wtf's
    realmName account, or account=<name>
  - the whole Account folder as it is in wtf-import\Account (for reference; the clients do not read it)
  benilla: `$env:BENILLA_HOME when set (cenilla reads it too), else each Code2\Wow\tools\benilla* checkout's
  benilla-config (a menu when there are several, Enter = all); cenilla: Code2\Wow\tools\cenilla\cenilla-config.

Usage: .\wow_wtf_fix.ps1 [classic|tbc|wotlk]     (default: wotlk, case insensitive)
       .\wow_wtf_fix.ps1 benilla|cenilla [benilla|cenilla] [account=<name>] [--debug]
       .\wow_wtf_fix.ps1 help | --help | -h
"@
}
if ($args | Where-Object { "$_" -in @('help', '--help', '-h') }) {
    Show-Usage
    exit 0
}

# --- benilla / cenilla: the classic install's WTF into the clients' own state folders ---

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
$CLIENT_WOW_ENV = 'wow_classic_dir'
$TOOLS_ROOT = Join-Path $env:code_root_dir 'Code2\Wow\tools'
# A benilla checkout is a benilla* dir holding the client crate (benilla.ps1's rule)
$BENILLA_PATTERN = 'benilla*'
$BENILLA_MANIFEST = 'crates\benilla\Cargo.toml'
$CENILLA_REPO_NAME = 'cenilla'
$STATE_DIR_NAMES = @{ 'benilla' = 'benilla-config'; 'cenilla' = 'cenilla-config' }
# Both clients take their state folder from it when it is set
$STATE_HOME_VAR = 'BENILLA_HOME'
$WTF_DIR_NAME = 'WTF'
$ACCOUNT_DIR_NAME = 'Account'
$CONFIG_WTF = 'Config.wtf'
$REALM_NAME_PATTERN = '^\s*SET\s+realmName\s+"([^"]*)"'
$SAVED_VARIABLES_DIR = 'SavedVariables'
$SAVED_VARIABLES_EXT = '.lua'
$SAVED_DIR = 'saved'
$WTF_IMPORT_DIR = 'wtf-import'
# The state folder's WTF equivalents, removed before the copy
$STATE_WTF_ITEMS = @('macros', 'bindings', 'layout', 'chat', 'camera', 'addon-state', $SAVED_DIR, 'config-cache', 'saved-variables.lua', 'cache.md5', $WTF_IMPORT_DIR)
# A character's WTF files: <dir>\<Realm>-<Char><ext> in the state folder
$CHARACTER_FILES = [ordered]@{
    'macros-cache.txt'    = @('macros', '.txt')
    'layout-cache.txt'    = @('layout', '.txt')
    'chat-cache.txt'      = @('chat', '.txt')
    'camera-settings.txt' = @('camera', '.txt')
    'AddOns.txt'          = @('addon-state', '.txt')
    'config-cache.wtf'    = @('config-cache', '.wtf')
    'bindings-cache.wtf'  = @('bindings', '.wtf')
}
# The chosen account's account-wide WTF files
$ACCOUNT_FILES = [ordered]@{
    'macros-cache.txt'   = 'macros\account.txt'
    'config-cache.wtf'   = 'config-cache\account.wtf'
    'bindings-cache.wtf' = 'bindings\account.wtf'
    'SavedVariables.lua' = 'saved-variables.lua'
    'cache.md5'          = 'cache.md5'
}
# A bindings-cache.wtf is also written as the diff the clients load a set from, beside it
$BINDINGS_WTF = 'bindings-cache.wtf'
$BINDINGS_DIFF_EXT = '.txt'
$BINDINGS_DIFF_HEADER = '# benilla key bindings - diff vs defaults (from bindings-cache.wtf by wow_wtf_fix)'
# The key names the clients' loader turns into their character (normalize_binding_key)
$BINDING_KEY_ALIASES = @{
    'LEFTBRACKET' = '['; 'RIGHTBRACKET' = ']'; 'SLASH' = '/'; 'BACKSLASH' = '\'; 'SEMICOLON' = ';'; 'APOSTROPHE' = "'"
    'COMMA' = ','; 'PERIOD' = '.'; 'TILDE' = '`'; 'PLUS' = '='; 'MINUS' = '-'
}
$UNKNOWN_TOKEN = 'unknown'
$script:DebugMode = $false
$script:Stats = @{}

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

function Copy-StateFile($source, $destination) {
    $parent = Split-Path -Path $destination -Parent
    Invoke-Step "New-Item -ItemType Directory -Force -Path $(Format-Arg $parent) | Out-Null; Copy-Item -LiteralPath $(Format-Arg $source) -Destination $(Format-Arg $destination) -Force" {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
    $script:Stats.Files++
}

function ConvertTo-BindingDiff($text) {
    # A bindings-cache.wtf as the clients' diff file (bindings::store::from_cache without the
    # defaults): its lines applied in order (a key bound again moves, an empty command unbinds),
    # then grouped by command; a command the file leaves unbound keeps the clients' default keys
    $table = New-Object System.Collections.Generic.List[object]
    foreach ($line in ($text -split "`r`n|`r|`n")) {
        if ($line.Length -lt 5 -or $line.Substring(0, 5) -ne 'bind ') { continue }
        $key, $command = $line.Substring(5) -split ' ', 2
        if ($BINDING_KEY_ALIASES.ContainsKey($key)) { $key = $BINDING_KEY_ALIASES[$key] }
        $key = $key.ToUpperInvariant()
        if (-not $key) { continue }
        for ($i = 0; $i -lt $table.Count; $i++) {
            if ($table[$i].Key -ceq $key) { $table.RemoveAt($i); break }
        }
        if ($command) { $table.Add([pscustomobject]@{ Key = $key; Command = $command.ToUpperInvariant() }) }
    }

    $order = New-Object System.Collections.Generic.List[string]
    $keysOf = @{}
    foreach ($row in $table) {
        if (-not $keysOf.ContainsKey($row.Command)) { $order.Add($row.Command); $keysOf[$row.Command] = @() }
        $keysOf[$row.Command] += $row.Key
    }
    $lines = @($BINDINGS_DIFF_HEADER) + @($order | ForEach-Object { "bind $_ $($keysOf[$_] -join ' ')" })
    return ($lines -join "`n") + "`n"
}

function Write-BindingDiff($source, $destination) {
    Invoke-Step "# write $(Format-Arg $destination) (the diff of $(Format-Arg $source))" {
        New-Item -ItemType Directory -Force -Path (Split-Path -Path $destination -Parent) | Out-Null
        $diff = ConvertTo-BindingDiff ([System.IO.File]::ReadAllText($source))
        [System.IO.File]::WriteAllText($destination, $diff, (New-Object System.Text.UTF8Encoding $false))
    }
    $script:Stats.Bindings++
}

function Copy-WtfFile($source, $destination) {
    # A WTF file into the state folder, a bindings-cache.wtf also as its diff
    Copy-StateFile $source $destination
    if ((Split-Path -Path $source -Leaf) -eq $BINDINGS_WTF) {
        Write-BindingDiff $source ([System.IO.Path]::ChangeExtension($destination, $BINDINGS_DIFF_EXT))
    }
}

function Copy-SavedVariables($sourceDir, $destinationDir) {
    # The addons' saved variables (<Addon>.lua, not the .bak copies)
    if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) { return }
    foreach ($file in Get-ChildItem -LiteralPath $sourceDir -File | Where-Object { $_.Extension -eq $SAVED_VARIABLES_EXT }) {
        Copy-StateFile $file.FullName (Join-Path $destinationDir $file.Name)
    }
}

function Resolve-SourceAccount($accountRoot, $wtfDir, $requested) {
    # The account whose account-wide files are copied: account=<name>, else the one holding
    # Config.wtf's realmName realm, else the only one
    $accounts = @(Get-ChildItem -LiteralPath $accountRoot -Directory)
    $names = ($accounts | ForEach-Object { $_.Name }) -join ', '
    if ($requested) {
        $match = @($accounts | Where-Object { $_.Name -eq $requested })
        if ($match.Count -eq 0) { Write-Err "No account $requested in $accountRoot (accounts: $names)."; exit 1 }
        return $match[0].Name
    }

    $realm = $null
    $config = Join-Path $wtfDir $CONFIG_WTF
    if (Test-Path -LiteralPath $config -PathType Leaf) {
        $line = Select-String -LiteralPath $config -Pattern $REALM_NAME_PATTERN | Select-Object -First 1
        if ($line) { $realm = $line.Matches[0].Groups[1].Value }
    }
    if ($realm) {
        $match = @($accounts | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName $realm) -PathType Container })
        if ($match.Count -gt 0) { return $match[0].Name }
    }
    if ($accounts.Count -eq 1) { return $accounts[0].Name }
    Write-Err "No account holds $CONFIG_WTF's realmName realm ($realm) - pass account=<name> (accounts: $names)."
    exit 1
}

function Select-BenillaCheckouts {
    # The benilla checkouts to copy into: the only one, else the picked ones (Enter = all)
    $checkouts = @(Get-ChildItem -LiteralPath $TOOLS_ROOT -Directory -Filter $BENILLA_PATTERN -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName $BENILLA_MANIFEST) -PathType Leaf } | Sort-Object Name)
    if ($checkouts.Count -eq 0) { Write-Err "No benilla checkout ($BENILLA_PATTERN holding $BENILLA_MANIFEST) under $TOOLS_ROOT."; exit 1 }
    if ($checkouts.Count -eq 1) { return $checkouts }

    Write-Info "benilla checkouts under ${TOOLS_ROOT}:"
    for ($i = 0; $i -lt $checkouts.Count; $i++) {
        $branch = git -C $checkouts[$i].FullName branch --show-current 2>$null
        Write-Host ("  {0}) {1,-22} {2}" -f ($i + 1), $checkouts[$i].Name, $branch)
    }
    if ([Console]::IsInputRedirected) { Write-Warn "No terminal to ask - copying into all of them."; return $checkouts }
    $answer = ([string](Read-Host "Copy into which? (Enter = all, or numbers like 1,3)")).Trim()
    if (-not $answer) { return $checkouts }

    $picked = @()
    foreach ($token in ($answer -split '[,\s]+' | Where-Object { $_ })) {
        $index = 0
        if (-not ([int]::TryParse($token, [ref]$index)) -or $index -lt 1 -or $index -gt $checkouts.Count) {
            Write-Err "Not a checkout number: $token (1-$($checkouts.Count))."
            exit 1
        }
        if ($picked -notcontains $checkouts[$index - 1]) { $picked += $checkouts[$index - 1] }
    }
    return $picked
}

function Get-ClientTargets($clients) {
    # The state folders to copy into: $env:BENILLA_HOME for both clients when set
    $homeDir = [Environment]::GetEnvironmentVariable($STATE_HOME_VAR)
    if ($homeDir) {
        Write-Info "`$env:$STATE_HOME_VAR is set - both clients use $homeDir."
        return @($homeDir)
    }
    $targets = @()
    if ($clients -contains 'benilla') {
        foreach ($checkout in Select-BenillaCheckouts) { $targets += Join-Path $checkout.FullName $STATE_DIR_NAMES['benilla'] }
    }
    if ($clients -contains 'cenilla') {
        $repo = Join-Path $TOOLS_ROOT $CENILLA_REPO_NAME
        if (-not (Test-Path -LiteralPath $repo -PathType Container)) { Write-Err "cenilla repo not found: $repo"; exit 1 }
        $targets += Join-Path $repo $STATE_DIR_NAMES['cenilla']
    }
    return $targets
}

function Copy-WtfInto($stateDir, $accountRoot, $mainAccount) {
    # Replaces the state folder's WTF files with the install's (see Show-Usage)
    $script:Stats = @{ Files = 0; Bindings = 0; Characters = 0 }
    Write-Info "-> $stateDir"
    foreach ($item in $STATE_WTF_ITEMS) {
        $path = Join-Path $stateDir $item
        if (Test-Path -LiteralPath $path) {
            Invoke-Step "Remove-Item -LiteralPath $(Format-Arg $path) -Recurse -Force" { Remove-Item -LiteralPath $path -Recurse -Force }
        }
    }

    $owners = @{}
    foreach ($account in Get-ChildItem -LiteralPath $accountRoot -Directory) {
        foreach ($realm in Get-ChildItem -LiteralPath $account.FullName -Directory | Where-Object { $_.Name -ne $SAVED_VARIABLES_DIR }) {
            foreach ($character in Get-ChildItem -LiteralPath $realm.FullName -Directory) {
                $key = "$(Get-FileToken $realm.Name)-$(Get-FileToken $character.Name)"
                if ($owners.ContainsKey($key)) { Write-Warn "  $key is in $($owners[$key]) and $($account.Name) - $($account.Name)'s files win." }
                $owners[$key] = $account.Name
                foreach ($name in $CHARACTER_FILES.Keys) {
                    $source = Join-Path $character.FullName $name
                    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }
                    $dir, $ext = $CHARACTER_FILES[$name]
                    Copy-WtfFile $source (Join-Path $stateDir "$dir\$key$ext")
                }
                Copy-SavedVariables (Join-Path $character.FullName $SAVED_VARIABLES_DIR) (Join-Path $stateDir "$SAVED_DIR\$key")
                $script:Stats.Characters++
            }
        }
    }

    $main = Join-Path $accountRoot $mainAccount
    foreach ($name in $ACCOUNT_FILES.Keys) {
        $source = Join-Path $main $name
        if (Test-Path -LiteralPath $source -PathType Leaf) { Copy-WtfFile $source (Join-Path $stateDir $ACCOUNT_FILES[$name]) }
    }
    Copy-SavedVariables (Join-Path $main $SAVED_VARIABLES_DIR) (Join-Path $stateDir $SAVED_DIR)

    $import = Join-Path $stateDir $WTF_IMPORT_DIR
    Invoke-Step "New-Item -ItemType Directory -Force -Path $(Format-Arg $import) | Out-Null; Copy-Item -LiteralPath $(Format-Arg $accountRoot) -Destination $(Format-Arg $import) -Recurse -Force" {
        New-Item -ItemType Directory -Force -Path $import | Out-Null
        Copy-Item -LiteralPath $accountRoot -Destination $import -Recurse -Force
    }
    Write-Ok "  $($script:Stats.Characters) characters, $($script:Stats.Files) files, $($script:Stats.Bindings) binding sets converted; account-wide files from $mainAccount; $ACCOUNT_DIR_NAME as it is in $WTF_IMPORT_DIR\$ACCOUNT_DIR_NAME"
}

$clients = @()
$requestedAccount = $null
$clientVersion = $null
$otherArgs = @()
foreach ($arg in $args) {
    $token = "$arg".ToLowerInvariant()
    if ($CLIENT_NAMES -contains $token) { if ($clients -notcontains $token) { $clients += $token } }
    elseif ($DEBUG_TOKENS -contains $token) { $script:DebugMode = $true }
    elseif ($token.StartsWith($ACCOUNT_ARG)) { $requestedAccount = "$arg".Substring($ACCOUNT_ARG.Length) }
    elseif ($VERSION_NAMES -contains $token) { $clientVersion = $token }
    else { $otherArgs += "$arg" }
}
if ($clients.Count -gt 0) {
    if ($otherArgs.Count -gt 0) { Write-Err "Unknown arg: $($otherArgs -join ' ') - see '.\wow_wtf_fix.ps1 help'."; exit 1 }
    if ($clientVersion -and $clientVersion -ne $CLIENT_VERSION) { Write-Err "benilla / cenilla are $CLIENT_VERSION (1.12.1) clients, not $clientVersion."; exit 1 }

    $wowRoot = [Environment]::GetEnvironmentVariable($CLIENT_WOW_ENV)
    if (-not $wowRoot) { Write-Err "`$env:$CLIENT_WOW_ENV is not set - set it to the classic install."; exit 1 }
    $wtfDir = Join-Path $wowRoot $WTF_DIR_NAME
    $accountRoot = Join-Path $wtfDir $ACCOUNT_DIR_NAME
    if (-not (Test-Path -LiteralPath $accountRoot -PathType Container)) {
        Write-Err "No WTF Account folder in the classic install: $accountRoot (`$env:$CLIENT_WOW_ENV)."
        exit 1
    }
    $mainAccount = Resolve-SourceAccount $accountRoot $wtfDir $requestedAccount
    Write-Info "Copying $accountRoot into $($clients -join ' / ') (account-wide files from $mainAccount)$(if ($script:DebugMode) { ' - debug: printing the commands only' })"
    foreach ($stateDir in @(Get-ClientTargets $clients | Select-Object -Unique)) {
        Copy-WtfInto $stateDir $accountRoot $mainAccount
    }
    Write-Ok "Done."
    exit 0
}

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
$wowRoot = (Get-Item "env:$wowEnv").Value
$destRoot = Join-Path $env:code_root_dir "Code2\Wow\addons\wow_addons\$addonSubDir"

# Ensure both paths exist
if (-not (Test-Path $destRoot)) {
    Write-Host "ERROR: Source addon directory not found: $destRoot" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $wowRoot)) {
    Write-Host "ERROR: WoW directory not found: $wowRoot" -ForegroundColor Red
    exit 1
}

Write-Host "Copying Account folder FROM $destRoot TO $wowRoot"

# Paths
$sourceAccount = Join-Path $destRoot 'Account'
$targetWtfDir = Join-Path $wowRoot 'WTF'
$targetAccount = Join-Path $targetWtfDir 'Account'

# Ensure WTF folder exists at destination
if (-not (Test-Path $targetWtfDir)) {
    Write-Host "WTF directory not found at $targetWtfDir, creating it..."
    New-Item -ItemType Directory -Path $targetWtfDir | Out-Null
}

# Replace Account folder
if (Test-Path $sourceAccount) {
    if (Test-Path $targetAccount) {
        Remove-Item -Path $targetAccount -Recurse -Force
        Write-Host "Removed existing Account folder at $targetAccount"
    }
    Copy-Item -Path $sourceAccount -Destination $targetWtfDir -Recurse -Force
    Write-Host "Copied Account folder -> $targetAccount"
}
else {
    Write-Host "WARNING: Source Account folder not found: $sourceAccount" -ForegroundColor Yellow
}

Write-Host "Done."

