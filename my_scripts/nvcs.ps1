<#
.SYNOPSIS
    Locate (or build) nvcs.exe and run it, forwarding all arguments.

.DESCRIPTION
    Scans {code_root_dir}/Code2/C#/my_cs/nvcs/src/nvcs/bin/<Config>/<Tfm>/ for nvcs.exe
    across every configuration (Debug/Release) and every target framework.

    Selection order:
      1. newest build time (max of CreationTime / LastWriteTime)
      2. on a tie (within $TieToleranceSeconds): highest .NET version wins
      3. still tied: Release beats Debug

    If nothing is built, runs `dotnet build` in the project dir, picking the newest
    TargetFramework from the csproj that is actually installed on this machine.

    All arguments given to this script are forwarded verbatim to nvcs.exe:
        .\nvcs.ps1 test.py --verbose
#>

# Everything on the command line belongs to nvcs.exe - capture it before anything else.
$ScriptArgs = $args

# ---------------------------------------------------------------------------
# Hard-coded options (intentionally NOT exposed as script arguments)
# ---------------------------------------------------------------------------
$UseRelease          = $false   # $true  => `dotnet build -c Release` instead of Debug
$DryRun              = $false   # $true  => print the commands instead of running them
$TieToleranceSeconds = 5        # build times within this many seconds count as "the same"

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Colored print helpers
# ---------------------------------------------------------------------------
function Write-Ok     ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err    ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn   ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info   ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt([string]$m) { Write-Host $m -ForegroundColor Magenta }

function Fail([string]$m) { Write-Err "ERROR: $m"; exit 1 }

# ---------------------------------------------------------------------------
# TFM helpers
# ---------------------------------------------------------------------------
# "net9.0", "net9.0-windows" -> [version]9.0 ; anything else -> $null
function Get-TfmVersion([string]$tfm) {
    if ($tfm -and $tfm -match '^net(\d+)\.(\d+)') { return [version]"$($Matches[1]).$($Matches[2])" }
    return $null
}

# Emits items one by one (no 'return'); EVERY caller wraps the result in @() so a
# single result is still an array. Do NOT use "return ,$arr" here - Windows
# PowerShell 5.1 then hands the caller one nested array object instead.
function Sort-TfmsDesc([string[]]$tfms) {
    $tfms | Sort-Object -Property @{ Expression = { Get-TfmVersion $_ }; Descending = $true }
}

# "9.0.100" / "9.0.0-preview.1" -> "net9.0"
function Convert-VersionToTfm([string]$ver) {
    if ($ver -match '^(\d+)\.(\d+)') { return "net$($Matches[1]).$($Matches[2])" }
    return $null
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$CodeRoot = $env:code_root_dir
if ([string]::IsNullOrWhiteSpace($CodeRoot)) {
    Fail "environment variable 'code_root_dir' is not set."
}

$ProjectDir = Join-Path $CodeRoot 'Code2/C#/my_cs/nvcs/src/nvcs'
$CsprojPath = Join-Path $ProjectDir 'nvcs.csproj'
$BinDir     = Join-Path $ProjectDir 'bin'
$ExeName    = if ($IsLinux -or $IsMacOS) { 'nvcs' } else { 'nvcs.exe' }

if (-not (Test-Path -LiteralPath $ProjectDir)) { Fail "project dir not found: $ProjectDir" }
if (-not (Test-Path -LiteralPath $CsprojPath)) { Fail "csproj not found: $CsprojPath" }

Write-Info "Project : $ProjectDir"
Write-Info "Csproj  : $CsprojPath"

# ---------------------------------------------------------------------------
# 1. Read target framework(s) from the csproj
# ---------------------------------------------------------------------------
$csprojText    = Get-Content -LiteralPath $CsprojPath -Raw
$ProjectTfms   = @()
$IsMultiTarget = $false

if ($csprojText -match '(?s)<TargetFrameworks>\s*(.*?)\s*</TargetFrameworks>') {
    $ProjectTfms = @(($Matches[1] -split ';') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $IsMultiTarget = $true
}
elseif ($csprojText -match '(?s)<TargetFramework>\s*(.*?)\s*</TargetFramework>') {
    $ProjectTfms = @($Matches[1].Trim())
}

if ($ProjectTfms.Count -eq 0) {
    Fail "no <TargetFramework> or <TargetFrameworks> element found in $CsprojPath"
}

$ProjectTfms = @(Sort-TfmsDesc $ProjectTfms)

if ($IsMultiTarget) {
    Write-InfoAlt "Csproj targets MULTIPLE frameworks ($($ProjectTfms.Count)): $($ProjectTfms -join ', ')"
} else {
    Write-InfoAlt "Csproj targets a SINGLE framework: $($ProjectTfms[0])"
}

# ---------------------------------------------------------------------------
# 2. Discover installed SDKs / runtimes
# ---------------------------------------------------------------------------
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Fail "'dotnet' was not found on PATH - install the .NET SDK."
}

$sdkLines     = @(& dotnet --list-sdks     2>$null)
$runtimeLines = @(& dotnet --list-runtimes 2>$null)

$SdkVersions = @($sdkLines | ForEach-Object {
    if ($_ -match '^(\S+)\s') { $Matches[1] }
})
$RuntimeVersions = @($runtimeLines | ForEach-Object {
    if ($_ -match '^Microsoft\.NETCore\.App\s+(\S+)') { $Matches[1] }
})

$SdkTfmsRaw     = @($SdkVersions     | ForEach-Object { Convert-VersionToTfm $_ } | Where-Object { $_ } | Select-Object -Unique)
$RuntimeTfmsRaw = @($RuntimeVersions | ForEach-Object { Convert-VersionToTfm $_ } | Where-Object { $_ } | Select-Object -Unique)

$SdkTfms     = @(Sort-TfmsDesc $SdkTfmsRaw)
$RuntimeTfms = @(Sort-TfmsDesc $RuntimeTfmsRaw)

if ($SdkTfms.Count -eq 0 -and $RuntimeTfms.Count -eq 0) {
    Fail "could not detect any installed .NET SDKs or runtimes (dotnet --list-sdks / --list-runtimes returned nothing)."
}

$AllInstalledRaw = @($SdkTfms) + @($RuntimeTfms) | Select-Object -Unique
$InstalledTfms   = @(Sort-TfmsDesc @($AllInstalledRaw))

Write-Info "Installed SDKs     : $(if ($SdkTfms.Count)     { $SdkTfms -join ', ' }     else { '(none)' })"
Write-Info "Installed runtimes : $(if ($RuntimeTfms.Count) { $RuntimeTfms -join ', ' } else { '(none)' })"
if ($InstalledTfms.Count) {
    Write-Info "Latest installed .NET framework: $($InstalledTfms[0])"
}

# csproj vs machine
$MatchingTfms = @(Sort-TfmsDesc @($ProjectTfms | Where-Object { $InstalledTfms -contains $_ }))
if ($MatchingTfms.Count -eq 0) {
    Write-Err "ERROR: none of the csproj target frameworks are installed on this machine."
    Write-Err "  csproj    : $($ProjectTfms -join ', ')"
    Write-Err "  installed : $($InstalledTfms -join ', ')"
    exit 1
}
Write-Ok "Usable framework(s) (csproj n installed): $($MatchingTfms -join ', ')"

# ---------------------------------------------------------------------------
# 3. Find existing builds
# ---------------------------------------------------------------------------
# Emits one object per found exe; callers wrap in @().
function Get-BuildCandidates {
    if (-not (Test-Path -LiteralPath $BinDir)) { return }

    $found = @(Get-ChildItem -LiteralPath $BinDir -Recurse -File -Filter $ExeName -ErrorAction SilentlyContinue)

    foreach ($f in $found) {
        $rel   = $f.FullName.Substring($BinDir.Length).TrimStart([char]'\', [char]'/')
        $parts = $rel -split '[\\/]'
        if ($parts.Count -lt 3) { continue }   # expect <Config>/<Tfm>/nvcs.exe

        $config = $parts[0]
        $tfm    = $parts[1]
        $ver    = Get-TfmVersion $tfm
        if (-not $ver) {
            Write-Warn "Skipping (unrecognized framework dir): $($f.FullName)"
            continue
        }

        $buildTime = if ($f.CreationTime -gt $f.LastWriteTime) { $f.CreationTime } else { $f.LastWriteTime }

        [pscustomobject]@{
            Path       = $f.FullName
            Config     = $config
            Tfm        = $tfm
            TfmVersion = $ver
            IsRelease  = ($config -ieq 'Release')
            BuildTime  = $buildTime
            Label      = "$config/$tfm"
        }
    }
}

function Select-BestBuild($candidates) {
    $candidates = @($candidates)
    $newest = ($candidates | Measure-Object -Property BuildTime -Maximum).Maximum
    $cutoff = $newest.AddSeconds(-$TieToleranceSeconds)
    $tied   = @($candidates | Where-Object { $_.BuildTime -ge $cutoff })

    $ordered = @($tied | Sort-Object `
        @{ Expression = { $_.TfmVersion }; Descending = $true }, `
        @{ Expression = { $_.IsRelease };  Descending = $true }, `
        @{ Expression = { $_.BuildTime };  Descending = $true })

    $best = $ordered[0]

    # Build a human explanation of why this one won.
    if ($candidates.Count -eq 1) {
        $reason = "it is the only build present."
    }
    elseif ($tied.Count -eq 1) {
        $others = @($candidates | Where-Object { $_.Path -ne $best.Path } | Sort-Object BuildTime -Descending)
        $gap    = [math]::Round(($best.BuildTime - $others[0].BuildTime).TotalSeconds)
        $reason = "it is the most recently compiled build ($gap s newer than the next one, $($others[0].Label))."
    }
    else {
        $why = @()
        if (@($tied | Where-Object { $_.TfmVersion -gt $best.TfmVersion }).Count -eq 0 -and
            @($tied | Where-Object { $_.TfmVersion -lt $best.TfmVersion }).Count -gt 0) {
            $why += "highest .NET version ($($best.Tfm))"
        }
        if ($best.IsRelease -and @($tied | Where-Object { -not $_.IsRelease }).Count -gt 0) {
            $why += "Release preferred over Debug"
        }
        if ($why.Count -eq 0) { $why += "first by build time" }
        $reason = "$($tied.Count) builds were compiled within $TieToleranceSeconds s of each other ($(($tied | ForEach-Object { $_.Label }) -join ', ')), so it won on: $($why -join ', ')."
    }

    [pscustomobject]@{ Best = $best; Reason = $reason; Tied = $tied }
}

$Candidates = @(Get-BuildCandidates)

# ---------------------------------------------------------------------------
# 4. Build if nothing exists
# ---------------------------------------------------------------------------
if ($Candidates.Count -eq 0) {
    if (Test-Path -LiteralPath $BinDir) {
        Write-Warn "No $ExeName found under $BinDir - building."
    } else {
        Write-Warn "No bin dir at $BinDir - building."
    }

    $buildConfig = if ($UseRelease) { 'Release' } else { 'Debug' }
    $buildTfm    = $MatchingTfms[0]

    $dotnetArgs = @('build', '-c', $buildConfig)
    if ($IsMultiTarget) {
        $dotnetArgs += @('-f', $buildTfm)
        Write-Info "Multi-target csproj -> building only $buildTfm (latest installed match)."
    } else {
        Write-Info "Single-target csproj -> no -f needed (framework is $buildTfm)."
    }

    Write-InfoAlt "Running: dotnet $($dotnetArgs -join ' ')   (cwd: $ProjectDir)"

    if ($DryRun) {
        Write-Warn "DryRun enabled - build skipped."
        exit 0
    }

    Push-Location -LiteralPath $ProjectDir
    try {
        & dotnet @dotnetArgs
        $buildExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    if ($buildExit -ne 0) { Fail "dotnet build failed with exit code $buildExit." }
    Write-Ok "Build succeeded ($buildConfig / $buildTfm)."

    $Candidates = @(Get-BuildCandidates)
    if ($Candidates.Count -eq 0) {
        Fail "build reported success but no $ExeName was found under $BinDir."
    }
}
else {
    Write-Info "Found $($Candidates.Count) build(s):"
    foreach ($c in @($Candidates | Sort-Object BuildTime -Descending)) {
        Write-Info ("  {0,-22} {1:yyyy-MM-dd HH:mm:ss}  {2}" -f $c.Label, $c.BuildTime, $c.Path)
    }
}

# ---------------------------------------------------------------------------
# 5. Pick the winner and validate it can run here
# ---------------------------------------------------------------------------
$sel  = Select-BestBuild $Candidates
$Best = $sel.Best

Write-Ok "Chosen : $($Best.Label) -> $($Best.Path)"
Write-Ok "Reason : $($sel.Reason)"

if ($RuntimeTfms.Count -gt 0 -and ($RuntimeTfms -notcontains $Best.Tfm)) {
    Write-Err "ERROR: the selected build targets $($Best.Tfm), but that runtime is not installed."
    Write-Err "  selected  : $($Best.Path)"
    Write-Err "  installed : $($RuntimeTfms -join ', ')"
    Write-Err "  Install the .NET $($Best.Tfm -replace '^net','') runtime, or rebuild for one of the installed versions."
    exit 1
}

# ---------------------------------------------------------------------------
# 6. Run, forwarding all script arguments
# ---------------------------------------------------------------------------
if ($ScriptArgs.Count -gt 0) {
    Write-InfoAlt "Forwarding args: $($ScriptArgs -join ' ')"
} else {
    Write-InfoAlt "No args to forward."
}

if ($DryRun) {
    Write-Warn "DryRun enabled - would run: `"$($Best.Path)`" $($ScriptArgs -join ' ')"
    exit 0
}

& $Best.Path @ScriptArgs
exit $LASTEXITCODE
