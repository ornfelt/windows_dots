# Usage:
# .acore              -> acore + npcbots (default)
# .acore n            -> acore + npcbots (also: npc, npcbot, npcbots)
# .acore p            -> acore + playerbots (also: pbot, pbots, playerbot, playerbots)
# .acore plain        -> plain acore (also: vanilla, 0, classic)
# .acore cs           -> C# azerothcore-wotlk-cs, npcbots build (also: c#)
# .acore cs p         -> C# azerothcore-wotlk-cs, playerbots build (second arg: n / p / plain as above)
# .acore help         -> show usage (also: --help, -h)

param(
    [Parameter(Position = 0)][string]$Variant = '',
    [Parameter(Position = 1)][string]$CsVariant = ''
)

function Write-Err  ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info ([string]$m) { Write-Host $m -ForegroundColor Cyan }

# Copied next to worldserver.exe by update_conf.py.
$UpdateConfScript = Join-Path -Path $env:my_notes_path -ChildPath "scripts\wow\update_conf.py"
$RequiredFiles = @("libmysql.dll", "libcrypto-3-x64.dll", "libssl-3-x64.dll", "legacy.dll")
# Only copied for the npcbots build.
$OverwriteScript = "overwrite.py"

function Show-Help {
    Write-Info "Usage: .acore [variant]"
    Write-Host "  (none), n, npc, npcbot, npcbots         acore + npcbots (default)"
    Write-Host "  p, pbot, pbots, playerbot, playerbots   acore + playerbots"
    Write-Host "  plain, vanilla, 0, classic              plain acore"
    Write-Host "  cs, c# [variant]                        C# azerothcore-wotlk-cs; variant as above (default npcbots)"
    Write-Host "  help, --help, -h                        show this help"
    Write-Host "cd's to the dir of the newest worldserver.exe build (or the C# repo) and prints the run command."
}

# The C# port runs from its repo root: it reads configs/, configs_npcbots/ or configs_playerbots/
# (by build flag) relative to the working dir, and copy_runtime_data.py fills them and copies
# overwrite.py there.
function Enter-CsRepo ([string]$csVariant) {
    if (-not $env:code_root_dir) {
        Write-Err "The code_root_dir environment variable is not set."
        return
    }

    if ($csVariant -match '^(|n|npc|npcbot|npcbots)$') {
        $label = "npcbots"; $copyProfile = "npcbots"; $confDir = "configs_npcbots"; $flag = " -p:Npcbots=true"
    } elseif ($csVariant -match '^(p|pbot|pbots|playerbot|playerbots)$') {
        $label = "playerbots"; $copyProfile = "playerbots"; $confDir = "configs_playerbots"; $flag = " -p:Playerbots=true"
    } elseif ($csVariant -match '^(plain|vanilla|0|classic)$') {
        $label = "plain"; $copyProfile = "core"; $confDir = "configs"; $flag = ""
    } else {
        Write-Err "Unknown C# variant '$csVariant'."
        Show-Help
        return
    }

    $csPath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C#\azerothcore-wotlk-cs"
    if (-not (Test-Path $csPath)) {
        Write-Warn "C# repo not found: $csPath"
        return
    }

    $csFiles = @("$confDir\worldserver.conf", "$confDir\authserver.conf")
    $sets = @("conf")
    if ($label -eq "playerbots") {
        $csFiles += "$confDir\modules\playerbots.conf"
        $sets += "playerbots"
    }
    if ($label -eq "npcbots") {
        $csFiles += $OverwriteScript
        $sets += "overwrite"
    }

    cd $csPath
    Write-Info "Using C# $label build: $csPath"

    $missing = @($csFiles | Where-Object { -not (Test-Path (Join-Path $csPath $_)) })
    if ($missing.Count -gt 0) {
        Write-Warn "Warning: missing in ${csPath}: $($missing -join ', ')"
        Write-Warn "Tip: run 'python copy_runtime_data.py --profiles $copyProfile --sets $($sets -join ',')' - it copies them there."
    }

    $run = "dotnet run --project src\Apps\Worldserver -c Release$flag"
    if ($label -eq "npcbots") {
        echo "python $csPath\$OverwriteScript; $run"
    } else {
        echo $run
    }
}

# -match is case insensitive.
if ($Variant -match '^(help|--help|-h)$') {
    Show-Help
    return
} elseif ($Variant -match '^(c#|cs)$') {
    Enter-CsRepo $CsVariant
    return
} elseif ($Variant -match '^(|n|npc|npcbot|npcbots)$') {
    $repo = "AzerothCore-wotlk-with-NPCBots"
    $RequiredFiles += $OverwriteScript
} elseif ($Variant -match '^(p|pbot|pbots|playerbot|playerbots)$') {
    $repo = "azerothcore-wotlk-playerbots"
} elseif ($Variant -match '^(plain|vanilla|0|classic)$') {
    $repo = "azerothcore-wotlk"
} else {
    Write-Err "Unknown variant '$Variant'."
    Show-Help
    return
}

$repoPath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\$repo"

# The newest worldserver.exe under <repo>/build*, the same one update_conf.py picks.
$basePath = $null
if (Test-Path $repoPath) {
    $newestExe = Get-ChildItem -Path $repoPath -Directory -Filter "build*" |
        ForEach-Object { Get-ChildItem -Path $_.FullName -Recurse -Depth 3 -Filter "worldserver.exe" -File -ErrorAction SilentlyContinue } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($newestExe) { $basePath = $newestExe.DirectoryName }
}

if ($basePath) {
    $path = $basePath
} elseif (Test-Path "D:\My files\svea_laptop\acore\azerothcore\build_eluna\bin\RelWithDebInfo") {
    $path = "D:\My files\svea_laptop\acore\azerothcore\build_eluna\bin\RelWithDebInfo"
} elseif (Test-Path "~/acore/bin") {
    $path = "~/acore/bin"
} else {
    Write-Warn "No worldserver.exe build found under $repoPath (and no ~/acore/bin fallback) - build it first."
    return
}

cd $path
Write-Info "Using $repo build: $path"

$missing = @($RequiredFiles | Where-Object { -not (Test-Path (Join-Path $path $_)) })
if ($missing.Count -gt 0) {
    Write-Warn "Warning: missing in ${path}: $($missing -join ', ')"
    Write-Warn "Tip: run '$("python $UpdateConfScript $Variant".Trim())' - it copies them there."
}

#echo "$path\worldserver.exe"
#Invoke-Expression "$path\worldserver.exe"

if ($RequiredFiles -contains $OverwriteScript) {
    echo "python $path\$OverwriteScript; $path\worldserver.exe"
} else {
    echo "$path\worldserver.exe"
}
#Invoke-Expression "python $path\overwrite.py; $path\worldserver.exe"

