# see:
# $env:my_notes_path/scripts/replace/cs/FindReplace/Program.cs
$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set." -ForegroundColor Red
    exit 1
}

$projectDir = Join-Path $notes "scripts/replace/cs/FindReplace"

if (-not (Test-Path $projectDir -PathType Container)) {
    Write-Host "FindReplace directory does not exist:" -ForegroundColor Red
    Write-Host "  $projectDir"
    exit 1
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "dotnet was not found in PATH." -ForegroundColor Red
    exit 1
}

function Get-FindReplaceExe {
    param(
        [Parameter(Mandatory)]
        [string] $ProjectDir
    )

    $configs = @("Release", "Debug")

    foreach ($config in $configs) {
        $binDir = Join-Path $ProjectDir "bin/$config"

        if (-not (Test-Path $binDir -PathType Container)) {
            continue
        }

        $exe = Get-ChildItem -Path $binDir `
            -Recurse `
            -Filter "find_replace.exe" `
            -File `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -match "[\\/]+net(\d+)\.0[\\/]+find_replace\.exe$"
            } |
            ForEach-Object {
                $match = [regex]::Match($_.FullName, "[\\/]+net(\d+)\.0[\\/]+find_replace\.exe$")
                $netVersion = [int]$match.Groups[1].Value

                [PSCustomObject]@{
                    File       = $_
                    NetVersion = $netVersion
                    Config     = $config
                }
            } |
            Sort-Object NetVersion -Descending |
            Select-Object -First 1

        if ($exe) {
            return $exe.File.FullName
        }
    }

    return $null
}

$exePath = Get-FindReplaceExe -ProjectDir $projectDir

if ([string]::IsNullOrWhiteSpace($exePath)) {
    Write-Host "Could not find find_replace.exe under:" -ForegroundColor Yellow
    Write-Host "  $projectDir/bin/Release/net*/find_replace.exe"
    Write-Host "  $projectDir/bin/Debug/net*/find_replace.exe"

    $answer = Read-Host "Do you want to run 'dotnet build -c Release' now? [y/N]"

    if ($answer -match '^(?i)y(?:es)?$') {
        Push-Location $projectDir
        try {
            Write-Host "Building FindReplace in Release mode..." -ForegroundColor Cyan

            dotnet build -c Release
            $buildExitCode = $LASTEXITCODE

            if ($buildExitCode -ne 0) {
                Write-Host "dotnet build failed with exit code $buildExitCode." -ForegroundColor Red
                exit $buildExitCode
            }
        }
        finally {
            Pop-Location
        }

        $exePath = Get-FindReplaceExe -ProjectDir $projectDir

        if ([string]::IsNullOrWhiteSpace($exePath)) {
            Write-Host "Build succeeded, but find_replace.exe was still not found." -ForegroundColor Red
            Write-Host "Checked:"
            Write-Host "  $projectDir/bin/Release/net*/find_replace.exe"
            Write-Host "  $projectDir/bin/Debug/net*/find_replace.exe"
            exit 1
        }
    }
    else {
        Write-Host "Build skipped. Cannot continue without find_replace.exe." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Running:" -ForegroundColor DarkGray
Write-Host "  $exePath"

& $exePath @args
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "find_replace.exe failed with exit code $exitCode." -ForegroundColor Red
    exit $exitCode
}

exit 0

