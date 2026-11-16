# d2x.ps1 - runs d2x ($env:code_root_dir\Code2\C\d2x: OpenDiablo2 ported to C) with the game's MPQs,
# as opend2.ps1 does for OpenDiablo2, and runs d2x's tools (tools\*.ps1 - gameplay, showcase,
# playthrough, netplay, smoke, ... - and extract_mpq), by name or from a menu. The PowerShell twin
# of the dotfiles' bin/my_scripts/2025/d2x.sh.
#
# Usage examples (`.d2x help` lists every option):
# play: the main menu, from the newest Release build (the Debug build when there is none):
# .d2x
#
# start on a screen and / or a window:device pair (positional), the Debug build:
# .d2x game
# .d2x charselect glfw:d3d11 --debug
# .d2x game:inventory -x vk
#
# heroes from another save dir, join a host, raw d2x flags (an option .d2x does not know goes to
# d2x with its value; everything after a quoted '--' goes to d2x as it is):
# .d2x --saves ~\d2heroes
# .d2x --join 127.0.0.1
# .d2x -F 300 -x d3d11
# .d2x '--' -l 5 -screen mapengine:12,301
# .d2x -dedicated -players 4
#
# the menu - play with options, run a tool from its usage examples, build:
# .d2x menu
# .d2x -m
#
# the tools: list them, run one (a unique prefix of its name is enough, its args after it):
# .d2x tools
# .d2x tool gameplay bar -Gear breath -Build whirlwind -Zone coldplains
# .d2x tool show nec -Order random
# .d2x tool smoke -h
#
# build d2x (Release into build_release by default, Debug into build):
# .d2x build
# .d2x build debug
#
# print the command instead of running it:
# .d2x game -n
#
# The MPQ dir is --data, else D2X_DATA, else the config's MpqPath, else d2x's default
# ($env:USERPROFILE\Downloads\d2\d2video); when that one holds no MPQs, the d2 dir is looked up as
# opend2.ps1 does ($env:USERPROFILE\Downloads\d2, else copied from a drive's 2024\d2) and passed
# with -p (D2X_DATA for the tools).

function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
function Write-Info ($text) { Write-Host "$text" -ForegroundColor Cyan }
function Write-Alt  ($text) { Write-Host "$text" -ForegroundColor Magenta }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red }

$codeRootDir = $env:code_root_dir
if (-not $codeRootDir) {
    $codeRootDir = $env:USERPROFILE
}

$REPO_ROOT = Join-Path -Path $codeRootDir -ChildPath "Code2\C\d2x"
$D2X_EXE = "d2x"
$TOOLS_DIR = "tools"
# Build dirs holding d2x; the newest d2x of the kind asked for is run. Multi-config builds (the
# Visual Studio generator, d2x's default on Windows) put it in <dir>\bin\<config>, the others in
# <dir>\bin (their CMakeCache.txt names the type)
$RELEASE_BUILD_DIRS = @("build_release", "build_rel_nt")
$DEBUG_BUILD_DIRS = @("build", "build_notests")
$DEFAULT_RELEASE_BUILD_DIR = "build_release"
$DEFAULT_DEBUG_BUILD_DIR = "build"
$MULTI_CONFIGS = @("Release", "RelWithDebInfo", "MinSizeRel", "Debug")
$DEBUG_CONFIG = "Debug"
# Sources whose change makes a build stale (warned about, not rebuilt)
$SOURCE_DIRS = @("src", "shaders")
# Command-line tools built next to d2x that the tool menu offers too
$BIN_TOOLS = @("extract_mpq")
# Known gfx backends, to tell a window:device pair from a screen like game:inventory
$KNOWN_WINDOWS = @("win32", "glfw", "sdl", "x11")
$KNOWN_DEVICES = @("gl3", "gl4", "gles3", "vk", "d3d11", "d3d12")
$DEFAULT_PAIR_TEXT = "D2X_GFX_WINDOW / D2X_GFX_DEVICE, else win32:gl4"
# d2x's flags that take no value (`d2x -h`); its other flags take one
$D2X_BOOL_FLAGS = @("cheats", "classic", "dedicated", "h", "hardcore", "v")
# A tool summary's longest length in the tool list
$SUMMARY_MAX = 90
$ESC = [char]27
$BOM = [char]0xFEFF

$CONFIG_DIR = Join-Path -Path $env:APPDATA -ChildPath "d2x"
$CONFIG_FILE = Join-Path -Path $CONFIG_DIR -ChildPath "config.json"
$D2_DIR_NAME = "d2"
$MPQ_SUBDIR = "d2video"
$DOWNLOADS_DIR = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
# d2x's own default (src/app/defaults.h, D2X_DEFAULT_MPQ_HOME_SUBDIR under the home dir)
$DEFAULT_MPQ_DIR = Join-Path -Path (Join-Path -Path $DOWNLOADS_DIR -ChildPath $D2_DIR_NAME) -ChildPath $MPQ_SUBDIR
$HDD_D2_SUBPATH = "2024\$D2_DIR_NAME"
$SPACE_MARGIN_BYTES = 5GB
# Mounted drives that are searched for 2024\d2 (network drives are skipped: they can hang when offline)
$HDD_DRIVE_TYPES = @([System.IO.DriveType]::Fixed, [System.IO.DriveType]::Removable)
# Local d2 dirs, checked in this order
$DIABLO_DIRS = @(
    (Join-Path -Path $DOWNLOADS_DIR -ChildPath $D2_DIR_NAME)
)

$USE_FZF = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
# fzf's items go through a file (FZF_DEFAULT_COMMAND), not a pipe: Windows PowerShell puts a BOM in
# front of what it pipes to a native command when the console's input encoding has one, and that
# BOM would be part of the first item (and of a preview's {1})
$FZF_ITEMS_FILE = Join-Path -Path $env:TEMP -ChildPath "d2x_fzf_items.txt"
$FZF_SHELL = "--with-shell=cmd /s /c"
# Windows PowerShell passes a native argument's inner double quotes unescaped
$ESCAPE_NATIVE_QUOTES = ($PSVersionTable.PSVersion.Major -lt 7) -or ($PSNativeCommandArgumentPassing -eq 'Legacy')

function Show-Usage {
    $lines = Get-Content -LiteralPath $PSCommandPath
    foreach ($line in $lines) {
        if ($line -notmatch '^#') { break }
        Write-Host ($line -replace '^# ?', '')
    }
    Write-Host @'

Commands (the first arg; none = play):
  menu, -m, --menu         the menu: play (with options), run a tool, build
  tools                    list the tools
  tool <name> [args]       run tools\<name>.ps1 (or a command-line tool: extract_mpq) with its args
                           (-h prints a tool's help: its header comment)
  build [release|debug|<dir>] [-n]
                           configure (once) and build d2x (default: release)
  help, -h, --help         this text

Play options (case-sensitive short ones, as d2x.sh has them; the long ones also as -Name):
  [screen]                 the -screen to start on (positional): game, charselect, game:inventory, ...
  [window:device]          the gfx pair (positional), e.g. glfw:d3d11
  -r, --release            the newest Release build (default; the Debug build when there is none)
  -D, --debug              the newest Debug build
  -b, --build-dir <dir>    this build dir (or bin dir) instead (relative to the repo or absolute)
  -s, --screen <name>      the screen, named
  -w, --window <name>      gfx window backend
  -x, --device <name>      gfx device backend
  -d, --data <dir>         the MPQ dir (passed with -p)
  -S, --saves <dir>        heroes saved in / read from this dir (D2X_SAVES)
  -j, --join <host>        join a TCP/IP host with the first hero (D2X_JOIN, -screen game unless named)
  -l, --log-level <n>      d2x's log level (0 none .. 5 debug)
  -n, --show-cmd           print the command instead of running it
  -<d2x flag> [value]      an option .d2x does not know goes to d2x, with its value (-F 300,
                           -dedicated, -players 4, ...)
  '--' <flags>             the rest goes to d2x as it is (quoted: PowerShell drops a bare --)
'@
}

function Format-Size([long]$bytes) {
    if ($bytes -ge 1GB) { return "{0:N1} GB" -f ($bytes / 1GB) }
    return "{0:N0} MB" -f ($bytes / 1MB)
}

# An arg the way it can be pasted into PowerShell; an array (a,b typed on the command line) as a,b
function Format-Arg($arg) {
    if ($arg -is [array]) { $arg = ($arg | ForEach-Object { "$_" }) -join ',' }
    $text = "$arg"
    if ($text -match '^[A-Za-z0-9_\-\.:/\\=,+@~]+$') { return $text }
    return "'" + $text.Replace("'", "''") + "'"
}

# A command (env assignments first) the way it can be pasted into PowerShell
function Format-Cmd($envTable, [string]$exe, [object[]]$cmdArgs) {
    $parts = @()
    if ($envTable) {
        # an assigned string is always quoted
        foreach ($key in $envTable.Keys) { $parts += "`$env:$key='$(([string]$envTable[$key]).Replace("'", "''"))';" }
    }
    $exeText = Format-Arg $exe
    if ($exeText.StartsWith("'")) { $exeText = "& $exeText" }
    $parts += $exeText
    foreach ($arg in $cmdArgs) { $parts += (Format-Arg $arg) }
    return ($parts -join ' ')
}

# The D2X_* environment, to put back after a run sets some (a script's $env changes would stay in the session)
function Save-D2xEnv {
    $saved = @{}
    Get-ChildItem env: | Where-Object { $_.Name -like 'D2X_*' } | ForEach-Object { $saved[$_.Name] = $_.Value }
    return $saved
}

function Restore-D2xEnv($saved) {
    Get-ChildItem env: | Where-Object { $_.Name -like 'D2X_*' -and -not $saved.ContainsKey($_.Name) } |
        ForEach-Object { Remove-Item -LiteralPath "env:$($_.Name)" -ErrorAction SilentlyContinue }
    foreach ($key in $saved.Keys) { Set-Item -LiteralPath "env:$key" -Value $saved[$key] }
}

function Resolve-RepoPath([string]$path) {
    if ($path.StartsWith('~')) { $path = $HOME + $path.Substring(1) }
    if ([System.IO.Path]::IsPathRooted($path)) { return $path }
    return (Join-Path -Path $REPO_ROOT -ChildPath $path)
}

function Enter-Repo {
    if (-not (Test-Path -LiteralPath $REPO_ROOT -PathType Container)) {
        Write-Err "$REPO_ROOT does not exist (code_root_dir: $codeRootDir)."
        exit 1
    }
    Set-Location -LiteralPath $REPO_ROOT
}

# ---- builds --------------------------------------------------------------------------------

function Get-BuildType([string]$dir) { # a build dir's CMAKE_BUILD_TYPE (or "?")
    $cache = Join-Path -Path (Resolve-RepoPath $dir) -ChildPath "CMakeCache.txt"
    if (Test-Path -LiteralPath $cache -PathType Leaf) {
        $match = Select-String -LiteralPath $cache -Pattern '^CMAKE_BUILD_TYPE:STRING=(.+)$' | Select-Object -First 1
        if ($match) { return $match.Matches[0].Groups[1].Value }
    }
    return "?"
}

# The <name>.exe files of build dirs: objects with Dir, Exe (as given: relative to the repo or
# absolute), Type (the configuration) and Time. A dir may also be a bin dir holding the exe.
function Get-BuildExes([string[]]$dirs, [string]$name) {
    foreach ($dir in $dirs) {
        $dir = $dir.TrimEnd('\', '/')
        $full = Resolve-RepoPath $dir
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { continue }
        $found = @()
        foreach ($config in $MULTI_CONFIGS) {
            $found += , @("$dir\bin\$config\$name.exe", $config)
        }
        $found += , @("$dir\bin\$name.exe", (Get-BuildType $dir))
        $leaf = Split-Path -Path $full -Leaf
        $leafType = "?"
        if ($MULTI_CONFIGS -contains $leaf) { $leafType = $leaf }
        $found += , @("$dir\$name.exe", $leafType)
        foreach ($entry in $found) {
            $exeFull = Resolve-RepoPath $entry[0]
            if (Test-Path -LiteralPath $exeFull -PathType Leaf) {
                [pscustomobject]@{
                    Dir  = $dir
                    Exe  = $entry[0]
                    Type = $entry[1]
                    Time = (Get-Item -LiteralPath $exeFull).LastWriteTime
                }
            }
        }
    }
}

function Select-Newest($exes) {
    return ($exes | Sort-Object -Property Time -Descending | Select-Object -First 1)
}

function Test-ReleaseType([string]$type) { return ($type -ne $DEBUG_CONFIG -and $type -ne "?") }

function Get-AllBuildDirs { return @($RELEASE_BUILD_DIRS + $DEBUG_BUILD_DIRS) }

function Find-NewerSource([string]$exe) { # the first source file newer than the exe, or $null
    $exeTime = [System.IO.File]::GetLastWriteTimeUtc((Resolve-RepoPath $exe))
    foreach ($dir in $SOURCE_DIRS) {
        $full = Join-Path -Path $REPO_ROOT -ChildPath $dir
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { continue }
        foreach ($file in [System.IO.Directory]::EnumerateFiles($full, '*', [System.IO.SearchOption]::AllDirectories)) {
            if ([System.IO.File]::GetLastWriteTimeUtc($file) -gt $exeTime) {
                return $file.Substring($REPO_ROOT.Length + 1)
            }
        }
    }
    return $null
}

# Picks the d2x to run (its path relative to the repo, or absolute): kind release / debug, or a build dir
function Resolve-Exe([string]$kind, [string]$buildDir, [bool]$kindAsked) {
    $exe = $null
    if ($buildDir) {
        $exes = @(Get-BuildExes @($buildDir) $D2X_EXE)
        if ($kindAsked) {
            $ofKind = @($exes | Where-Object { (Test-ReleaseType $_.Type) -eq ($kind -eq "release") })
            if ($ofKind.Count) { $exes = $ofKind }
        }
        $exe = Select-Newest $exes
        if (-not $exe) { Write-Err "$buildDir holds no $D2X_EXE.exe. Build it first (.d2x build)."; return $null }
    } elseif ($kind -eq "debug") {
        $exe = Select-Newest @(Get-BuildExes (Get-AllBuildDirs) $D2X_EXE | Where-Object { $_.Type -eq $DEBUG_CONFIG })
        if (-not $exe) { Write-Err "No Debug build of d2x ($((Get-AllBuildDirs) -join ' ')). Build it first: .d2x build debug"; return $null }
    } else {
        $exe = Select-Newest @(Get-BuildExes (Get-AllBuildDirs) $D2X_EXE | Where-Object { Test-ReleaseType $_.Type })
        if (-not $exe) {
            $exe = Select-Newest @(Get-BuildExes (Get-AllBuildDirs) $D2X_EXE)
            if (-not $exe) { Write-Err "No build of d2x yet. Build it first: .d2x build"; return $null }
            Write-Warn "No Release build ($($RELEASE_BUILD_DIRS -join ' ')) - running the Debug build. .d2x build makes one."
        }
    }
    $changed = Find-NewerSource $exe.Exe
    if ($changed) {
        $rebuild = "debug"
        if (Test-ReleaseType $exe.Type) { $rebuild = "release" }
        Write-Warn "$($exe.Exe) is older than $changed - rebuild with: .d2x build $rebuild"
    }
    return $exe.Exe
}

function Invoke-Build([object[]]$buildArgs) { # build [release|debug|<build dir>] [-n]
    $which = "release"
    $showCmd = $false
    foreach ($arg in $buildArgs) {
        $text = "$arg"
        if ($text -in @('-n', '--show-cmd', '-ShowCmd')) { $showCmd = $true } else { $which = $text }
    }
    switch -Regex ($which) {
        '^(release|r)$' { $dir = $DEFAULT_RELEASE_BUILD_DIR; $type = "Release"; break }
        '^(debug|d)$'   { $dir = $DEFAULT_DEBUG_BUILD_DIR; $type = $DEBUG_CONFIG; break }
        default {
            $dir = $which.TrimEnd('\', '/')
            $type = Get-BuildType $dir
            if ($type -eq "?") { $type = $DEBUG_CONFIG }
        }
    }
    $configureArgs = @("-S", ".", "-B", $dir, "-DCMAKE_BUILD_TYPE=$type")
    $buildCmdArgs = @("--build", $dir, "--config", $type, "--target", $D2X_EXE, "--parallel")
    $configured = Test-Path -LiteralPath (Join-Path -Path (Resolve-RepoPath $dir) -ChildPath "CMakeCache.txt") -PathType Leaf
    if ($showCmd) {
        if (-not $configured) { Write-Alt (Format-Cmd $null "cmake" $configureArgs) }
        Write-Alt (Format-Cmd $null "cmake" $buildCmdArgs)
        return
    }
    if (-not $configured) {
        Write-Info "Configuring $dir ($type)..."
        Write-Alt (Format-Cmd $null "cmake" $configureArgs)
        & cmake @configureArgs
        if ($LASTEXITCODE -ne 0) { Write-Err "Configuring $dir failed."; return }
    }
    Write-Info "Building $D2X_EXE in $dir ($type)..."
    Write-Alt (Format-Cmd $null "cmake" $buildCmdArgs)
    & cmake @buildCmdArgs
    if ($LASTEXITCODE -eq 0) {
        $built = Select-Newest @(Get-BuildExes @($dir) $D2X_EXE | Where-Object { $_.Type -eq $type -or $_.Type -eq "?" })
        if ($built) { Write-Ok "Built $($built.Exe)" } else { Write-Ok "Built $D2X_EXE in $dir" }
    } else {
        Write-Err "Building $dir failed."
    }
}

# ---- game data -----------------------------------------------------------------------------

function Test-HasMpqs([string]$dir) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir -PathType Container)) { return $false }
    return [bool](Get-ChildItem -LiteralPath $dir -Filter "*.mpq" -File -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Get-ConfigMpqPath([string[]]$files) { # the MpqPath of a config.json (the exe dir's wins over the user's)
    foreach ($file in @($files) + $CONFIG_FILE) {
        if (-not $file -or -not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $match = [regex]::Match([System.IO.File]::ReadAllText($file), '"MpqPath"\s*:\s*"((?:[^"\\]|\\.)*)"')
        if ($match.Success) { return $match.Groups[1].Value.Replace('\\', '\') }
        return $null
    }
    return $null
}

# Finds the d2 dir as opend2.ps1 does - a local one, else a copy from a mounted drive - and returns
# its MPQ dir (or $null)
function Find-D2MpqDir {
    $d2Dir = $DIABLO_DIRS | Where-Object { Test-HasMpqs (Join-Path -Path $_ -ChildPath $MPQ_SUBDIR) } | Select-Object -First 1
    if ($d2Dir) { return (Join-Path -Path $d2Dir -ChildPath $MPQ_SUBDIR) }

    Write-Warn "No local Diablo 2 directory found (checked: $($DIABLO_DIRS -join ', ')). Looking on mounted drives..."
    $systemDrive = "$env:SystemDrive\"
    $hddCandidates = [System.IO.DriveInfo]::GetDrives() |
        Where-Object { $_.IsReady -and ($HDD_DRIVE_TYPES -contains $_.DriveType) -and ($_.Name -ne $systemDrive) } |
        ForEach-Object { Join-Path -Path $_.Name -ChildPath $HDD_D2_SUBPATH }
    $hddD2Dir = $hddCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -First 1
    if (-not $hddD2Dir) {
        Write-Err "No Diablo 2 directory found locally ($($DIABLO_DIRS -join ', ')) or on a mounted drive (<drive>:\$HDD_D2_SUBPATH)."
        return $null
    }

    $d2Dir = Join-Path -Path $DOWNLOADS_DIR -ChildPath $D2_DIR_NAME
    if (Test-Path -LiteralPath $d2Dir) {
        Write-Err "$d2Dir exists but holds no MPQs in $MPQ_SUBDIR - not overwriting it."
        return $null
    }
    if (-not (Test-Path -LiteralPath $DOWNLOADS_DIR -PathType Container)) {
        New-Item -ItemType Directory -Path $DOWNLOADS_DIR | Out-Null
    }
    $d2Size = (Get-ChildItem -LiteralPath $hddD2Dir -Recurse -File -Force | Measure-Object -Property Length -Sum).Sum
    if (-not $d2Size) { $d2Size = 0 }
    $freeSpace = (New-Object System.IO.DriveInfo (Split-Path -Path $DOWNLOADS_DIR -Qualifier)).AvailableFreeSpace
    $neededSpace = $d2Size + $SPACE_MARGIN_BYTES
    Write-Label "Found $hddD2Dir ($(Format-Size $d2Size)). Free in ${DOWNLOADS_DIR}: $(Format-Size $freeSpace), needed (+$(Format-Size $SPACE_MARGIN_BYTES) margin): $(Format-Size $neededSpace)"
    if ($freeSpace -lt $neededSpace) {
        Write-Err "Not enough disk space to copy $hddD2Dir into $DOWNLOADS_DIR."
        return $null
    }

    # Copy into a temporary dir first, so an interrupted copy never looks like a complete d2 dir
    $partialDir = "$d2Dir.partial"
    if (Test-Path -LiteralPath $partialDir) {
        Write-Warn "Removing the leftover $partialDir of an interrupted copy"
        Remove-Item -LiteralPath $partialDir -Recurse -Force -Confirm:$false
    }
    Write-Info "Copying $hddD2Dir into $d2Dir..."
    robocopy $hddD2Dir $partialDir /E /NDL /NJH /NJS | Out-Host
    # robocopy exit codes below 8 mean success
    if ($LASTEXITCODE -ge 8) {
        Write-Err "Copying $hddD2Dir into $partialDir failed (robocopy exit code $LASTEXITCODE)."
        return $null
    }
    Rename-Item -LiteralPath $partialDir -NewName $D2_DIR_NAME
    Write-Ok "Copied $hddD2Dir into $d2Dir"
    return (Join-Path -Path $d2Dir -ChildPath $MPQ_SUBDIR)
}

# The MPQ dir to use: an object with Dir and Found ($true when d2x / the tools would not find it on
# their own), or $null. Mode play: d2x reads the config too; tools: D2X_DATA or the default only
function Resolve-MpqDir([string]$asked, [string]$exe, [string]$mode) {
    if ($asked) {
        $asked = Resolve-RepoPath $asked
        if (-not (Test-HasMpqs $asked)) { Write-Warn "$asked holds no MPQs." }
        return [pscustomobject]@{ Dir = $asked; Found = $true }
    }
    if ($env:D2X_DATA) {
        $effective = $env:D2X_DATA
    } elseif ($mode -eq "play") {
        $exeConfig = $null
        if ($exe) { $exeConfig = Join-Path -Path (Split-Path -Path (Resolve-RepoPath $exe) -Parent) -ChildPath "config.json" }
        $effective = Get-ConfigMpqPath @($exeConfig)
        if (-not $effective) { $effective = $DEFAULT_MPQ_DIR }
    } else {
        $effective = $DEFAULT_MPQ_DIR
    }
    $effective = $effective.TrimEnd('\', '/')
    if (Test-HasMpqs $effective) { return [pscustomobject]@{ Dir = $effective; Found = $false } }
    Write-Warn "No MPQs in $effective - looking for the Diablo 2 directory..."
    $dir = Find-D2MpqDir
    if (-not $dir) { return $null }
    Write-Label "Using the MPQs in $dir"
    return [pscustomobject]@{ Dir = $dir; Found = $true }
}

# ---- play ----------------------------------------------------------------------------------

function Test-Pair([string]$text) {
    if ($text -notmatch '^([^:]+):([^:]+)$') { return $false }
    return ($KNOWN_WINDOWS -contains $Matches[1]) -and ($KNOWN_DEVICES -contains $Matches[2])
}

# The play command from the play options: an object with Env (ordered), Exe, Args and ShowCmd, or $null
function Build-PlayCmd([object[]]$playArgs) {
    $kind = "release"; $kindAsked = $false
    $buildDir = ""; $screen = ""; $window = ""; $device = ""; $data = ""; $saves = ""; $join = ""; $logLevel = ""
    $showCmd = $false
    $extra = @()
    $i = 0
    $count = @($playArgs).Count
    while ($i -lt $count) {
        $arg = $playArgs[$i]
        $text = "$arg"
        $next = $null
        if ($i + 1 -lt $count) { $next = "$($playArgs[$i + 1])" }
        $takesValue = $true
        if ($text -ceq '-r' -or $text -eq '--release' -or $text -eq '-Release') { $kind = "release"; $kindAsked = $true; $takesValue = $false }
        elseif ($text -ceq '-D' -or $text -eq '--debug' -or $text -eq '-Debug') { $kind = "debug"; $kindAsked = $true; $takesValue = $false }
        elseif ($text -ceq '-n' -or $text -eq '--show-cmd' -or $text -eq '-ShowCmd') { $showCmd = $true; $takesValue = $false }
        elseif ($text -ceq '-b' -or $text -eq '--build-dir' -or $text -eq '-BuildDir') { $buildDir = $next }
        elseif ($text -ceq '-s' -or $text -eq '--screen' -or $text -eq '-Screen') { $screen = $next }
        elseif ($text -ceq '-w' -or $text -eq '--window' -or $text -eq '-Window') { $window = $next }
        elseif ($text -ceq '-x' -or $text -eq '--device' -or $text -eq '-Device') { $device = $next }
        elseif ($text -ceq '-d' -or $text -eq '--data' -or $text -eq '-Data') { $data = $next }
        elseif ($text -ceq '-S' -or $text -eq '--saves' -or $text -eq '-Saves') { $saves = $next }
        elseif ($text -ceq '-j' -or $text -eq '--join' -or $text -eq '-Join') { $join = $next }
        elseif ($text -ceq '-l' -or $text -eq '--log-level' -or $text -eq '-LogLevel') { $logLevel = $next }
        elseif ($text -eq '--') { $extra = @($playArgs | Select-Object -Skip ($i + 1)); break }
        elseif ($text.StartsWith('-')) {
            # not ours: a d2x flag, with its value unless it takes none (PowerShell drops an unquoted --)
            $extra += , $arg
            $takesValue = $false
            if ($D2X_BOOL_FLAGS -notcontains $text.TrimStart('-') -and $null -ne $next) {
                $extra += , $playArgs[$i + 1]
                $i++
            }
        } else {
            $takesValue = $false
            if (Test-Pair $text) {
                $window, $device = $text.Split(':')
            } elseif (-not $screen) {
                $screen = $text
            } else {
                Write-Err "unexpected arg: $text (the screen is $screen already)"
                return $null
            }
        }
        if ($takesValue) {
            if ($null -eq $next) { Write-Err "$text needs a value (.d2x help lists the options)"; return $null }
            $i++
        }
        $i++
    }

    $exe = Resolve-Exe $kind $buildDir $kindAsked
    if (-not $exe) { return $null }
    $mpq = Resolve-MpqDir $data $exe "play"
    if (-not $mpq) { return $null }

    $playEnv = [ordered]@{}
    if ($saves) { $playEnv["D2X_SAVES"] = (Resolve-RepoPath $saves) }
    if ($join) {
        $playEnv["D2X_JOIN"] = $join
        if (-not $screen) { $screen = "game" }
    }
    if (-not [System.IO.Path]::IsPathRooted($exe)) { $exe = ".\$exe" }
    $cmdArgs = @()
    if ($mpq.Found) { $cmdArgs += @("-p", $mpq.Dir) }
    if ($window) { $cmdArgs += @("-w", $window) }
    if ($device) { $cmdArgs += @("-x", $device) }
    if ($logLevel) { $cmdArgs += @("-l", $logLevel) }
    if ($screen) { $cmdArgs += @("-screen", $screen) }
    # a native exe takes text: an array typed as a,b goes as a,b
    foreach ($arg in $extra) {
        if ($arg -is [array]) { $cmdArgs += (($arg | ForEach-Object { "$_" }) -join ',') } else { $cmdArgs += "$arg" }
    }
    return [pscustomobject]@{ Env = $playEnv; Exe = $exe; Args = $cmdArgs; ShowCmd = $showCmd }
}

function Invoke-Play([object[]]$playArgs) {
    $cmd = Build-PlayCmd $playArgs
    if (-not $cmd) { return }
    $text = Format-Cmd $cmd.Env $cmd.Exe $cmd.Args
    if ($cmd.ShowCmd) { Write-Alt $text; return }
    Write-Label "Running: $text"
    $saved = Save-D2xEnv
    try {
        foreach ($key in $cmd.Env.Keys) { Set-Item -LiteralPath "env:$key" -Value $cmd.Env[$key] }
        $exeArgs = $cmd.Args
        & $cmd.Exe @exeArgs
        if ($LASTEXITCODE -ne 0) { Write-Warn "$D2X_EXE exited with status $LASTEXITCODE." }
    } finally {
        Restore-D2xEnv $saved
    }
}

# ---- tools ---------------------------------------------------------------------------------

function Get-BinToolPath([string]$name) { # the newest build's <name>.exe (relative to the repo)
    $exe = Select-Newest @(Get-BuildExes (Get-AllBuildDirs) $name)
    if ($exe) { return $exe.Exe }
    return $null
}

function Get-ToolNames { # the tools: tools\*.ps1, then the command-line tools built
    Get-ChildItem -LiteralPath (Join-Path -Path $REPO_ROOT -ChildPath $TOOLS_DIR) -Filter "*.ps1" -File |
        Sort-Object -Property Name | ForEach-Object { $_.BaseName }
    foreach ($name in $BIN_TOOLS) {
        if (Get-BinToolPath $name) { $name }
    }
}

function Get-ToolScript([string]$name) { return (Join-Path -Path $REPO_ROOT -ChildPath "$TOOLS_DIR\$name.ps1") }

function Get-ToolHeader([string]$name) { # a tools\*.ps1's header comment, without the #
    foreach ($line in (Get-Content -LiteralPath (Get-ToolScript $name))) {
        if ($line -notmatch '^#') { break }
        $line -replace '^# ?', ''
    }
}

function Get-ToolSummary([string]$name) { # one line about a tool: its header's first line
    if (Test-Path -LiteralPath (Get-ToolScript $name) -PathType Leaf) {
        $line = (Get-Content -LiteralPath (Get-ToolScript $name) -TotalCount 1) -replace '^# *(d2x: *)?', ''
    } else {
        $line = "extracts or lists an MPQ archive (build\bin)"
    }
    if ($line.Length -gt $SUMMARY_MAX) { $line = $line.Substring(0, $SUMMARY_MAX - 3) + "..." }
    return $line
}

function Resolve-Tool([string]$want) { # the tool's name, from its name or a unique prefix
    $names = @(Get-ToolNames)
    $exact = $names | Where-Object { $_ -eq $want } | Select-Object -First 1
    if ($exact) { return $exact }
    $matched = @($names | Where-Object { $_ -like "$want*" })
    if ($matched.Count -eq 1) { return $matched[0] }
    if ($matched.Count -gt 1) {
        Write-Err "`"$want`" names several tools: $($matched -join ' ')"
    } else {
        Write-Err "No tool `"$want`". The tools: $($names -join ' ')"
    }
    return $null
}

function Get-ToolCmdPrefix([string]$name) { # how a tool is run, relative to the repo
    if (Test-Path -LiteralPath (Get-ToolScript $name) -PathType Leaf) { return "$TOOLS_DIR\$name.ps1" }
    $exe = Get-BinToolPath $name
    if ($exe -and -not [System.IO.Path]::IsPathRooted($exe)) { $exe = ".\$exe" }
    return $exe
}

function Show-Tools {
    Write-Info "d2x tools (.d2x tool <name> [args]; <name> -h for its help):"
    foreach ($name in Get-ToolNames) {
        Write-Host ("  {0,-18} " -f $name) -ForegroundColor Green -NoNewline
        Write-Host (Get-ToolSummary $name)
    }
}

function Show-ToolHelp([string]$name) {
    $prefix = Get-ToolCmdPrefix $name
    if ($prefix -like "*.ps1") {
        Get-ToolHeader $name | Out-Host
    } else {
        & $prefix -h 2>&1 | ForEach-Object { "$_" } | Out-Host
    }
}

# Sets D2X_DATA when the MPQs are not where the tools look ($false when there are none)
function Initialize-ToolEnv {
    $mpq = Resolve-MpqDir "" "" "tools"
    if (-not $mpq) { return $false }
    if ($mpq.Found -and -not $env:D2X_DATA) {
        $env:D2X_DATA = $mpq.Dir
        Write-Label "D2X_DATA=$env:D2X_DATA"
    }
    return $true
}

function Invoke-Tool([object[]]$toolArgs) { # tool <name> [args...]
    $name = Resolve-Tool "$($toolArgs[0])"
    if (-not $name) { return }
    $rest = @($toolArgs | Select-Object -Skip 1)
    $prefix = Get-ToolCmdPrefix $name
    $isScript = $prefix -like "*.ps1"
    foreach ($arg in $rest) {
        if ("$arg" -in @('-h', '--help', '-Help', '-?')) { Show-ToolHelp $name; return }
    }
    # d2x.sh's spelling of the tools' -ShowCmd, as a named argument (a string the script makes is
    # splatted as a positional one: only the command line's own -names are taken as names)
    $named = @{}
    if ($isScript -and @($rest | Where-Object { "$_" -ceq '-n' -or "$_" -eq '--show-cmd' }).Count) {
        $rest = @($rest | Where-Object { -not ("$_" -ceq '-n' -or "$_" -eq '--show-cmd') })
        $named["ShowCmd"] = $true
    }
    # -ShowCmd and list need no game data
    $needsEnv = -not $named.Count
    foreach ($arg in $rest) {
        if ("$arg" -in @('-ShowCmd', '-n', 'list')) { $needsEnv = $false }
    }
    $saved = Save-D2xEnv
    try {
        if ($needsEnv -and -not (Initialize-ToolEnv)) { return }
        $shownArgs = $rest
        if ($named.Count) { $shownArgs = @($rest) + '-ShowCmd' }
        Write-Label "Running: $(Format-Cmd $null $prefix $shownArgs)"
        & (Resolve-RepoPath $prefix) @rest @named
    } finally {
        Restore-D2xEnv $saved
    }
}

# A tool's usage examples as objects with Cmd and Desc: from the "Usage examples:" part of a
# tools\*.ps1's header, from the -h text's "Examples:" of a command-line tool
function Get-ToolExamples([string]$name) {
    $prefix = Get-ToolCmdPrefix $name
    if ($prefix -like "*.ps1") {
        $inExamples = $false
        $desc = ""
        $descDone = $true
        foreach ($line in (Get-ToolHeader $name)) {
            if ($line -like "Usage examples:*") { $inExamples = $true; continue }
            if (-not $inExamples) { continue }
            if ($line -match '^\s{2,}(\S.*)$') {
                [pscustomobject]@{ Cmd = $Matches[1].Trim(); Desc = $desc }
                $descDone = $true
            } elseif ($line -match '^\S') {
                # a description may wrap onto more lines
                if ($descDone) { $desc = $line } else { $desc = "$desc $line" }
                $desc = $desc.TrimEnd(':')
                $descDone = $false
            }
        }
    } else {
        # the examples name the exe's full path and a bare archive: the repo-relative exe, the MPQ dir
        $mpqDir = $env:D2X_DATA
        if (-not $mpqDir) {
            $mpqDir = $DEFAULT_MPQ_DIR
            $local = $DIABLO_DIRS | ForEach-Object { Join-Path -Path $_ -ChildPath $MPQ_SUBDIR } | Where-Object { Test-HasMpqs $_ } | Select-Object -First 1
            if (-not (Test-HasMpqs $mpqDir) -and $local) { $mpqDir = $local }
        }
        $exeFull = Resolve-RepoPath ($prefix -replace '^\.\\', '')
        $inExamples = $false
        foreach ($line in (& $prefix -h 2>&1 | ForEach-Object { "$_" })) {
            if ($line -like "Examples:*") { $inExamples = $true; continue }
            if (-not $inExamples -or $line -notmatch '^\s+(\S.*)$') { continue }
            $cmd = $Matches[1].Replace($exeFull, $prefix)
            $cmd = [regex]::Replace($cmd, ' ([A-Za-z0-9_]+\.mpq)', { param($m) " " + (Format-Arg (Join-Path -Path $mpqDir -ChildPath $m.Groups[1].Value)) })
            [pscustomobject]@{ Cmd = $cmd; Desc = "example" }
        }
    }
}

# ---- menu ----------------------------------------------------------------------------------

# A native argument as Windows PowerShell passes it: inner double quotes escaped for the exe's parser,
# and the trailing backslashes of one it wraps in quotes (it has a space) doubled
function ConvertTo-NativeArg([string]$text) {
    if (-not $ESCAPE_NATIVE_QUOTES) { return $text }
    $text = [regex]::Replace($text, '(\\*)"', { param($m) $m.Groups[1].Value * 2 + '\"' })
    if ($text -match '\s') { $text = [regex]::Replace($text, '(\\+)$', { param($m) $m.Groups[1].Value * 2 }) }
    return $text
}

# Picks one of the items (the part before a TAB is returned, the part after it shown dimmed with
# fzf or in parentheses); $null when cancelled (Esc / q)
function Select-Item([string]$prompt, [string[]]$items, [string[]]$fzfArgs = @()) {
    if (-not $items -or $items.Count -eq 0) { return $null }
    if ($USE_FZF) {
        $shown = foreach ($item in $items) {
            $parts = $item -split "`t", 2
            if ($parts.Count -eq 2) { "$($parts[0])`t$ESC[90m$($parts[1])$ESC[0m" } else { $item }
        }
        [System.IO.File]::WriteAllText($FZF_ITEMS_FILE, (@($shown) -join "`n") + "`n", (New-Object System.Text.UTF8Encoding $false))
        $savedCommand = $env:FZF_DEFAULT_COMMAND
        $env:FZF_DEFAULT_COMMAND = "type `"$FZF_ITEMS_FILE`""
        try {
            $selected = fzf --ansi "--prompt=$prompt> " --height=60% --reverse --no-multi --tiebreak=index '--delimiter=\t' --tabstop=4 $FZF_SHELL @fzfArgs
            $status = $LASTEXITCODE
        } finally {
            if ($null -eq $savedCommand) { Remove-Item -LiteralPath env:FZF_DEFAULT_COMMAND -ErrorAction SilentlyContinue } else { $env:FZF_DEFAULT_COMMAND = $savedCommand }
        }
        if ($status -ne 0 -or -not $selected) { return $null }
        $selected = ("$(@($selected)[0])" -replace "$ESC\[[0-9;]*m", '') -replace "`t.*$", ''
        return $selected.Trim($BOM, "`r")
    }
    while ($true) {
        Write-Info "${prompt}:"
        for ($i = 0; $i -lt $items.Count; $i++) {
            $parts = $items[$i] -split "`t", 2
            $label = $parts[0]
            if ($parts.Count -eq 2) { $label = "$($parts[0])  ($($parts[1]))" }
            Write-Host ("  {0,2}) {1}" -f ($i + 1), $label)
        }
        $choice = Read-Host "number (q to go back)"
        if (-not $choice -or $choice -eq 'q') { return $null }
        $number = 0
        if ([int]::TryParse($choice, [ref]$number) -and $number -ge 1 -and $number -le $items.Count) {
            return ($items[$number - 1] -split "`t", 2)[0]
        }
    }
}

# Shows a command line to edit (Enter runs it, Esc / an empty line goes back), then runs it in the repo
function Invoke-EditAndRun([string]$line) {
    if ($USE_FZF) {
        Write-Info "Edit the command - Enter runs it, Esc goes back:"
        $out = @('') | fzf --disabled --print-query "--query=$(ConvertTo-NativeArg $line)" '--prompt=> ' --height=3 --info=hidden --reverse
        if ($LASTEXITCODE -ne 0) { return }
        $line = "$(@($out)[0])".Trim($BOM)
    } else {
        Write-Info "The command - Enter runs it, or type the command to run instead (q goes back):"
        Write-Alt $line
        $answer = Read-Host ">"
        if ($answer -eq 'q') { return }
        if ($answer) { $line = $answer }
    }
    if (-not $line.Trim()) { return }
    Write-Label "Running: $line"
    $saved = Save-D2xEnv
    Push-Location -LiteralPath $REPO_ROOT
    $global:LASTEXITCODE = 0
    $failed = $false
    try {
        Invoke-Expression $line
    } catch {
        Write-Err $_
        $failed = $true
    } finally {
        Pop-Location
        Restore-D2xEnv $saved
    }
    if (-not $failed -and $global:LASTEXITCODE -eq 0) { Write-Ok "Done." } else { Write-Warn "Exited with status $global:LASTEXITCODE." }
}

function Get-Screens([string]$exe) { # the -screen / capture scene names a d2x lists
    & (Resolve-RepoPath ($exe -replace '^\.\\', '')) -C list 2>&1 | ForEach-Object { "$_" } |
        Where-Object { $_ -match '^  ([a-z_][a-z_0-9]*) ' } | ForEach-Object { $Matches[1] }
}

function Get-Pairs([string]$exe) { # the window:device pairs a d2x was built with
    $help = @(& (Resolve-RepoPath ($exe -replace '^\.\\', '')) -h 2>&1 | ForEach-Object { "$_" })
    $windows = ($help | Where-Object { $_ -match '^\s*windows:\s*(.*)$' } | ForEach-Object { $Matches[1] } | Select-Object -First 1)
    $devices = ($help | Where-Object { $_ -match '^\s*devices:\s*(.*)$' } | ForEach-Object { $Matches[1] } | Select-Object -First 1)
    foreach ($w in "$windows".Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) {
        foreach ($d in "$devices".Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) { "${w}:$d" }
    }
}

function Invoke-QuickPlay([object[]]$playArgs) { # the default build, the command shown to edit
    $cmd = Build-PlayCmd $playArgs
    if (-not $cmd) { return }
    Invoke-EditAndRun (Format-Cmd $cmd.Env $cmd.Exe $cmd.Args)
}

function Invoke-MenuPlayOptions {
    $exes = @(Get-BuildExes (Get-AllBuildDirs) $D2X_EXE)
    if ($exes.Count -eq 0) { Write-Err "No build of d2x yet - build it first."; return }
    $items = foreach ($exe in $exes) {
        "$(Split-Path -Path $exe.Exe -Parent)`t$($exe.Type), built $($exe.Time.ToString('yyyy-MM-dd HH:mm'))"
    }
    $binDir = Select-Item "Build" $items
    if (-not $binDir) { return }
    $exe = "$binDir\$D2X_EXE.exe"

    $pair = Select-Item "Window:device" (@("default`t$DEFAULT_PAIR_TEXT") + @(Get-Pairs $exe))
    if (-not $pair) { return }
    $screen = Select-Item "Screen (game:<panel> and more: edit the command)" (@("mainmenu`tthe default: the trademark screen, then the main menu") + @(Get-Screens $exe))
    if (-not $screen) { return }
    $choice = Select-Item "Heroes" @("default`t$CONFIG_DIR\Saves", "another directory`tD2X_SAVES")
    if (-not $choice) { return }
    $saves = ""
    if ($choice -eq "another directory") {
        $saves = Read-Host "save directory"
        if (-not $saves) { return }
    }

    $playArgs = @("-b", $binDir)
    if ($pair -ne "default") { $playArgs += $pair }
    if ($screen -ne "mainmenu") { $playArgs += @("-s", $screen) }
    if ($saves) { $playArgs += @("-S", $saves) }
    Invoke-QuickPlay $playArgs
}

function Invoke-MenuTool {
    $names = @(Get-ToolNames)
    $items = foreach ($name in $names) { "$name`t$(Get-ToolSummary $name)" }
    # fzf's preview: each tool's header in a file named after it, shown with cmd's type
    $previewDir = Join-Path -Path $env:TEMP -ChildPath "d2x_tool_previews"
    New-Item -ItemType Directory -Force -Path $previewDir | Out-Null
    foreach ($name in $names) {
        $text = "extracts or lists an MPQ archive"
        if (Test-Path -LiteralPath (Get-ToolScript $name) -PathType Leaf) { $text = (Get-ToolHeader $name) -join "`r`n" }
        [System.IO.File]::WriteAllText((Join-Path -Path $previewDir -ChildPath $name), $text)
    }
    Push-Location -LiteralPath $previewDir
    try {
        $name = Select-Item "Tool" $items @('--preview=type {1}', '--preview-window=right,55%,wrap')
    } finally {
        Pop-Location
    }
    if (-not $name) { return }

    $prefix = Get-ToolCmdPrefix $name
    while ($true) {
        $examples = @(Get-ToolExamples $name)
        $exampleItems = foreach ($example in $examples) { "$($example.Cmd)`t$($example.Desc)" }
        $choice = Select-Item $name (@("(your own args)`t$prefix ...", "(help)`t$prefix -h") + @($exampleItems))
        if (-not $choice) { return }
        if ($choice -eq "(help)") {
            Show-ToolHelp $name
            continue
        }
        if ($choice -eq "(your own args)") { $choice = "$prefix " }
        $saved = Save-D2xEnv
        try {
            if (-not (Initialize-ToolEnv)) { return }
            Invoke-EditAndRun $choice
        } finally {
            Restore-D2xEnv $saved
        }
    }
}

function Invoke-MenuBuild {
    $choice = Select-Item "Build" @(
        "release`tRelease into $DEFAULT_RELEASE_BUILD_DIR (fast, for playing)",
        "debug`tDebug into $DEFAULT_DEBUG_BUILD_DIR (what the tools use by default)")
    if ($choice) { Invoke-Build @($choice) }
}

function Invoke-Menu {
    if ([Console]::IsInputRedirected) {
        Write-Err "The menu needs a terminal."
        return
    }
    if (-not $USE_FZF) { Write-Label "fzf is not installed - a numbered menu instead." }
    while ($true) {
        $choice = Select-Item "d2x" @(
            "Play`tthe main menu, the newest Release build",
            "Play: the first hero`t-screen game",
            "Play: character select`t-screen charselect",
            "Play with options`tbuild, window:device, screen, save directory",
            "Dedicated server`t-dedicated, no window (TCP/IP port 6669)",
            "Run a tool`tgameplay, showcase, playthrough, netplay, smoke, capture, tests, ... from their usage examples",
            "Build d2x`tRelease or Debug",
            "Quit")
        switch ($choice) {
            "Play"                   { Invoke-QuickPlay @() }
            "Play: the first hero"   { Invoke-QuickPlay @("-s", "game") }
            "Play: character select" { Invoke-QuickPlay @("-s", "charselect") }
            "Play with options"      { Invoke-MenuPlayOptions }
            "Dedicated server"       { Invoke-QuickPlay @("--", "-dedicated", "-players", "8") }
            "Run a tool"             { Invoke-MenuTool }
            "Build d2x"              { Invoke-MenuBuild }
            default                  { return }
        }
        Write-Host ""
    }
}

# ---- main ----------------------------------------------------------------------------------

Enter-Repo

$command = ""
if ($args.Count -gt 0) { $command = "$($args[0])" }
$rest = @($args | Select-Object -Skip 1)

if ($command -in @('menu', '-m', '--menu', '-Menu')) {
    Invoke-Menu
} elseif ($command -eq 'tools') {
    Show-Tools
} elseif ($command -in @('tool', 't')) {
    if ($rest.Count -eq 0) { Show-Tools } else { Invoke-Tool $rest }
} elseif ($command -eq 'build') {
    Invoke-Build $rest
} elseif ($command -in @('help', '-h', '--help', '-Help')) {
    Show-Usage
} else {
    Invoke-Play @($args)
}
