# cmake_helper.ps1 - launcher for the CmakeHelper GUI / CLI
#
# No param() block on purpose: CmakeHelper takes short options (-p, -d, -r, -j, ...)
# and a [Parameter(ValueFromRemainingArguments)] block would bind those to the
# parameter itself by prefix match instead of passing them on. $args forwards
# everything verbatim.
#
# Usage examples:
#   .cmake_helper                          open the ImGui GUI for the current directory
#   .cmake_helper --tui                    open the Terminal UI instead
#   .cmake_helper --print                  print the cmake command for the current directory
#   .cmake_helper --print --alternatives   ... plus the vcpkg / variant alternatives
#   .cmake_helper --copy                   copy the cmake command to the clipboard
#   .cmake_helper --run --build            configure, then build
#   .cmake_helper --debug-cmd              print the shell one-liner instead of running it
#   .cmake_helper --help                   full option list

$ErrorActionPreference = "Stop"

# ── Locate the project via code_root_dir ─────────────────────────────
$codeRoot = $Env:code_root_dir
if ([string]::IsNullOrWhiteSpace($codeRoot)) {
    Write-Host "Environment variable 'code_root_dir' is not set." -ForegroundColor Red
    exit 1
}

$projectDir = Join-Path $codeRoot "Code2/C#/my_csharp/CmakeHelper"
$csproj = Join-Path $projectDir "CmakeHelper.csproj"

if (-not (Test-Path $csproj)) {
    Write-Host "CmakeHelper.csproj not found at: $projectDir" -ForegroundColor Red
    exit 1
}

# ── Find or build the exe ────────────────────────────────────────────
$releaseExe = Join-Path $projectDir "bin/Release/net9.0/CmakeHelper.exe"
$debugExe   = Join-Path $projectDir "bin/Debug/net9.0/CmakeHelper.exe"

if (Test-Path $releaseExe) {
    $exePath = $releaseExe
}
elseif (Test-Path $debugExe) {
    $exePath = $debugExe
}
else {
    Write-Host "Building CmakeHelper..." -ForegroundColor Cyan
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

# ── Run (from the caller's directory - that is what the patterns match) ──
if ($exePath -and (Test-Path $exePath)) {
    & $exePath @args
}
else {
    # Fall back to dotnet run
    dotnet run --project $projectDir -c Release -- @args
}

exit $LASTEXITCODE
