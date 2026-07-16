param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PassthroughArgs
)

# script_helper.ps1 - launcher for the ScriptHelper GUI / CLI

$ErrorActionPreference = "Stop"

# ── Locate the project via code_root_dir ─────────────────────────────
$codeRoot = $Env:code_root_dir
if ([string]::IsNullOrWhiteSpace($codeRoot)) {
    Write-Host "Environment variable 'code_root_dir' is not set." -ForegroundColor Red
    exit 1
}

$projectDir = Join-Path $codeRoot "Code2/C#/my_csharp/ScriptHelper"
$csproj = Join-Path $projectDir "ScriptHelper.csproj"

if (-not (Test-Path $csproj)) {
    Write-Host "ScriptHelper.csproj not found at: $projectDir" -ForegroundColor Red
    exit 1
}

# ── Find or build the exe ────────────────────────────────────────────
$releaseExe = Join-Path $projectDir "bin/Release/net8.0/ScriptHelper.exe"
$debugExe   = Join-Path $projectDir "bin/Debug/net8.0/ScriptHelper.exe"

if (Test-Path $releaseExe) {
    $exePath = $releaseExe
}
elseif (Test-Path $debugExe) {
    $exePath = $debugExe
}
else {
    Write-Host "Building ScriptHelper..." -ForegroundColor Cyan
    Push-Location $projectDir
    try {
        dotnet build -c Release --nologo -v quiet
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed." -ForegroundColor Red
            exit 1
        }
    }
    finally {
        Pop-Location
    }
    $exePath = $releaseExe
}

# ── Run ──────────────────────────────────────────────────────────────
if ($exePath -and (Test-Path $exePath)) {
    & $exePath @PassthroughArgs
}
else {
    # Fall back to dotnet run
    dotnet run --project $projectDir -c Release -- @PassthroughArgs
}

exit $LASTEXITCODE
