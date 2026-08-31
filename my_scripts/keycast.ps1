param(
    [Parameter(Position=0)]
    [string]$Arg,

    [Parameter(Position=1)]
    [string]$Arg2
)

# keycast.ps1 - start KeyCastOW, the on-screen keystroke display.
#
# The exe is looked up under:
#   $Env:code_root_dir/Code/c++/KeyCastOW/build/<Config>/keycastow.exe
#
# Usage:
#   .\keycast.ps1                    run Release if it exists, otherwise Debug
#   .\keycast.ps1 r | release        force Release
#   .\keycast.ps1 d | debug          force Debug
#   .\keycast.ps1 rd | rwdi          force RelWithDebInfo
#   .\keycast.ps1 r foo              force Release + PRINT-ONLY
#   .\keycast.ps1 onlyprint          print the command instead of running it
#   .\keycast.ps1 kill               stop a running keycastow.exe (asks y/N)
#   .\keycast.ps1 h | --help         show help

# ---------- Colored prints ----------
function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Ok   { param([string]$Message) Write-Host $Message -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Err  { param([string]$Message) Write-Host $Message -ForegroundColor Red }
function Write-Step { param([string]$Message) Write-Host $Message -ForegroundColor DarkGray }

# ---------- Constants ----------
$ExeName        = 'keycastow.exe'
$ProcessName    = 'keycastow'
$BuildRelPath   = 'Code/c++/KeyCastOW/build'
$DefaultConfigs = @('Release', 'Debug')

# ---------- Help ----------
function Show-Help {
@"
keycast.ps1 - start KeyCastOW (on-screen keystroke display)

Usage:
  .\keycast.ps1
      Run $ExeName from the Release build, falling back to Debug.

  .\keycast.ps1 r | release
      Force the Release build.

  .\keycast.ps1 d | debug
      Force the Debug build.

  .\keycast.ps1 rd | rwdi | relwithdebinfo
      Force the RelWithDebInfo build.

  .\keycast.ps1 r foo
      Release + PRINT-ONLY (any second arg flips to print-only).

  .\keycast.ps1 onlyprint
      Print the command that would be run, without running it.

  .\keycast.ps1 kill
      Stop the running $ExeName (asks for y/N confirmation).

  .\keycast.ps1 h | help | -h | --help
      Show this help.

Notes:
  - Without r/d/rd the script tries Release first, then Debug.
  - The exe is expected under:
        `$Env:code_root_dir/$BuildRelPath/<Config>/$ExeName
"@ | Write-Output
}

$helpTokens = @('h','help','-h','--help')
if (
    (-not [string]::IsNullOrWhiteSpace($Arg)  -and $helpTokens -contains $Arg.ToLowerInvariant()) -or
    (-not [string]::IsNullOrWhiteSpace($Arg2) -and $helpTokens -contains $Arg2.ToLowerInvariant())
) {
    Show-Help
    exit 0
}

# ---------- kill ----------
if (-not [string]::IsNullOrWhiteSpace($Arg) -and $Arg.ToLowerInvariant() -eq 'kill') {
    $running = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)

    if ($running.Count -eq 0) {
        Write-Warn "No running $ExeName was found."
        exit 0
    }

    Write-Info "Running $ExeName process(es):"
    foreach ($proc in $running) {
        Write-Host ("  PID {0}  (started {1})" -f $proc.Id, $proc.StartTime)
    }

    $answer = Read-Host "Kill $($running.Count) process(es)? [y/N]"

    if ($answer -notmatch '^(?i)y(?:es)?$') {
        Write-Warn "Aborted, nothing was killed."
        exit 0
    }

    $failed = 0
    foreach ($proc in $running) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Ok "Killed PID $($proc.Id)."
        }
        catch {
            Write-Err "Could not kill PID $($proc.Id): $($_.Exception.Message)"
            $failed++
        }
    }

    if ($failed -gt 0) { exit 1 }
    exit 0
}

# ---------- Arg parsing ----------
$OnlyPrint      = $null
$Release        = $false
$RelWithDebInfo = $false
$Debug_         = $false

if (-not [string]::IsNullOrWhiteSpace($Arg)) {
    $arg_lc = $Arg.ToLowerInvariant()

    if ($arg_lc -eq 'r' -or $arg_lc -eq 'release') {
        $Release = $true
        if (-not [string]::IsNullOrWhiteSpace($Arg2)) { $OnlyPrint = 'true' }
    }
    elseif ($arg_lc -eq 'rwdi' -or $arg_lc -eq 'rd' -or $arg_lc -eq 'relwithdebinfo') {
        $RelWithDebInfo = $true
        if (-not [string]::IsNullOrWhiteSpace($Arg2)) { $OnlyPrint = 'true' }
    }
    elseif ($arg_lc -eq 'd' -or $arg_lc -eq 'debug') {
        $Debug_ = $true
        if (-not [string]::IsNullOrWhiteSpace($Arg2)) { $OnlyPrint = 'true' }
    }
    else {
        $OnlyPrint = 'true'
    }
}

$BuildType = $null
if     ($Release)        { $BuildType = 'Release' }
elseif ($RelWithDebInfo) { $BuildType = 'RelWithDebInfo' }
elseif ($Debug_)         { $BuildType = 'Debug' }

# ---------- Locate the exe ----------
$root = $env:code_root_dir

if ([string]::IsNullOrWhiteSpace($root)) {
    Write-Err "Environment variable 'code_root_dir' is not set."
    exit 1
}

$buildDir = Join-Path $root $BuildRelPath

if (-not (Test-Path $buildDir -PathType Container)) {
    Write-Err "KeyCastOW build directory does not exist:"
    Write-Host "  $buildDir"
    exit 1
}

$configs = $DefaultConfigs
if ($BuildType) { $configs = @($BuildType) }

$exePath = $null
foreach ($config in $configs) {
    $candidate = Join-Path (Join-Path $buildDir $config) $ExeName

    if (Test-Path $candidate -PathType Leaf) {
        $exePath = $candidate
        $BuildType = $config
        break
    }
}

if ([string]::IsNullOrWhiteSpace($exePath)) {
    Write-Err "Could not find $ExeName under:"
    foreach ($config in $configs) {
        Write-Host "  $(Join-Path (Join-Path $buildDir $config) $ExeName)"
    }
    Write-Output ""
    Write-Info "If needed, build it with:"
    Write-Info "  cmake --build `"$buildDir`" --config $($configs[0])"
    exit 1
}

$workingDir = Split-Path -Parent $exePath

# ---------- Print-only ----------
if ($OnlyPrint) {
    Write-Info "Would run ($BuildType):"
    Write-Host "  Start-Process -FilePath `"$exePath`" -WorkingDirectory `"$workingDir`""
    exit 0
}

# ---------- Run ----------
$running = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)

if ($running.Count -gt 0) {
    Write-Warn "$ExeName is already running (PID $($running.Id -join ', '))."
    Write-Warn "Run '.\keycast.ps1 kill' to stop it first."
    exit 0
}

Write-Step "Running ($BuildType):"
Write-Host "  $exePath"

try {
    Start-Process -FilePath $exePath -WorkingDirectory $workingDir -ErrorAction Stop
}
catch {
    Write-Err "Failed to start $ExeName : $($_.Exception.Message)"
    exit 1
}

Write-Ok "$ExeName started."
exit 0
