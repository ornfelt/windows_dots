param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PassthroughArgs
)

# db_helper.ps1 - launcher for the DbHelper GUI / CLI

$ErrorActionPreference = "Stop"

# ── Locate the project via code_root_dir ─────────────────────────────
$codeRoot = $Env:code_root_dir
if ([string]::IsNullOrWhiteSpace($codeRoot)) {
    Write-Host "Environment variable 'code_root_dir' is not set." -ForegroundColor Red
    exit 1
}

$projectDir = Join-Path $codeRoot "Code2/C#/my_csharp/DbHelper"
$csproj = Join-Path $projectDir "DbHelper.csproj"

if (-not (Test-Path $csproj)) {
    Write-Host "DbHelper.csproj not found at: $projectDir" -ForegroundColor Red
    exit 1
}

# ── Helpers ──────────────────────────────────────────────────────────
function Get-TfmMajor([string]$tfm) {
    # net9.0, net8.0-windows, ... -> 9, 8; anything else -> 0
    $m = [regex]::Match($tfm, '^net(\d+)\.')
    if ($m.Success) { return [int]$m.Groups[1].Value }
    return 0
}

function Get-DotnetMajors([string[]]$Lines, [string]$Pattern) {
    $majors = New-Object System.Collections.Generic.List[int]
    foreach ($line in $Lines) {
        if ($line -match $Pattern) {
            $major = [int]$Matches[1]
            if (-not $majors.Contains($major)) { $majors.Add($major) }
        }
    }
    return @($majors.ToArray() | Sort-Object -Descending)
}

function Find-Exe([int]$Major) {
    foreach ($config in @("Release", "Debug")) {
        $configDir = Join-Path $projectDir "bin/$config"
        if (-not (Test-Path $configDir)) { continue }
        $tfmDirs = @(Get-ChildItem -LiteralPath $configDir -Directory -Filter "net*" -ErrorAction SilentlyContinue |
            Where-Object { (Get-TfmMajor $_.Name) -eq $Major })
        foreach ($tfmDir in $tfmDirs) {
            $exe = Join-Path $tfmDir.FullName "DbHelper.exe"
            if (Test-Path $exe) { return $exe }
        }
    }
    return $null
}

# ── Detect the .NET SDK / runtimes actually installed ─────────────────
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "dotnet was not found on PATH." -ForegroundColor Red
    exit 1
}

$sdkMajors     = Get-DotnetMajors (dotnet --list-sdks)     '^(\d+)\.'
$runtimeMajors = Get-DotnetMajors (dotnet --list-runtimes) '^Microsoft\.NETCore\.App\s+(\d+)\.'

if (-not $sdkMajors.Count) {
    Write-Host "No .NET SDK is installed." -ForegroundColor Red
    exit 1
}
$maxSdkMajor = $sdkMajors[0]

# ── Pick the target framework to use ─────────────────────────────────
# What the csproj asks for, newest first.
$projectTfms = @()
$tfmMatch = [regex]::Match((Get-Content -Raw -LiteralPath $csproj), '<TargetFrameworks?>([^<]+)</TargetFrameworks?>')
if ($tfmMatch.Success) {
    $projectTfms = @($tfmMatch.Groups[1].Value -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        Sort-Object -Property { Get-TfmMajor $_ } -Descending)
}

# Usable = the installed SDK can build it and a matching runtime exists.
$usableTfms = @($projectTfms | Where-Object {
    $major = Get-TfmMajor $_
    ($major -gt 0) -and ($major -le $maxSdkMajor) -and ($runtimeMajors -contains $major)
})

$buildTfm = $null   # $null means: let the csproj decide
$targetMajor = 0
if ($usableTfms.Count) {
    $targetMajor = Get-TfmMajor $usableTfms[0]
}
else {
    # Nothing the csproj asks for is available here - retarget to the newest runtime the SDK can build.
    $installable = @($runtimeMajors | Where-Object { $_ -le $maxSdkMajor })
    if (-not $installable.Count) {
        Write-Host "No .NET runtime usable with SDK $maxSdkMajor is installed." -ForegroundColor Red
        exit 1
    }
    $targetMajor = $installable[0]
    $buildTfm = "net$targetMajor.0"
    $asked = if ($projectTfms.Count) { $projectTfms -join ", " } else { "an unknown framework" }
    Write-Host "Project targets $asked, which is not available here - using $buildTfm." -ForegroundColor Yellow
}

# ── Find or build the exe ────────────────────────────────────────────
$exePath = Find-Exe -Major $targetMajor

if (-not $exePath) {
    # Any earlier build output the installed runtimes can still run.
    foreach ($major in $runtimeMajors) {
        $exePath = Find-Exe -Major $major
        if ($exePath) { break }
    }
}

if (-not $exePath) {
    Write-Host "Building DbHelper for net$targetMajor.0..." -ForegroundColor Cyan
    $buildArgs = @("build", "-c", "Release", "--nologo", "-v", "quiet")
    if ($buildTfm) { $buildArgs += "-p:TargetFramework=$buildTfm" }
    Push-Location $projectDir
    try {
        & dotnet @buildArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed." -ForegroundColor Red
            exit 1
        }
    }
    finally {
        Pop-Location
    }
    $exePath = Find-Exe -Major $targetMajor
}

# ── Run ──────────────────────────────────────────────────────────────
if ($exePath -and (Test-Path $exePath)) {
    # Let a newer runtime host an exe built against a framework that is now gone.
    $exeMajor = Get-TfmMajor (Split-Path -Leaf (Split-Path -Parent $exePath))
    if (($exeMajor -gt 0) -and ($runtimeMajors -notcontains $exeMajor)) {
        $Env:DOTNET_ROLL_FORWARD = "LatestMajor"
    }
    & $exePath @PassthroughArgs
}
else {
    # Fall back to dotnet run
    $runArgs = @("run", "--project", $projectDir, "-c", "Release")
    if ($buildTfm) { $runArgs += @("-f", $buildTfm) }
    & dotnet @runArgs -- @PassthroughArgs
}

exit $LASTEXITCODE
