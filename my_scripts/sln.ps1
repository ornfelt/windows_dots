param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

function Write-Info($message) {
    Write-Host $message -ForegroundColor Cyan
}

function Write-Warn($message) {
    Write-Host $message -ForegroundColor Yellow
}

function Write-Usage {
    Write-Host "Usage:"
    Write-Host "  open-sln.ps1"
    Write-Host "  open-sln.ps1 any-arg"
    Write-Host ""
    Write-Host "Without args:"
    Write-Host "  Opens the first .slnx/.sln found in current dir, build dir, or parent dir."
    Write-Host ""
    Write-Host "With any non-help arg:"
    Write-Host "  Also checks direct child dirs for .slnx/.sln files."
    Write-Host "  If one is found, opens it."
    Write-Host "  If several are found, prints relative paths instead."
}

function Get-FirstFile($pattern) {
    Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-Files($pattern) {
    @(Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue)
}

function Get-RelativePathFromCwd($path) {
    $cwd = (Get-Location).Path

    try {
        return [System.IO.Path]::GetRelativePath($cwd, $path)
    }
    catch {
        # Windows PowerShell 5.1 fallback
        $cwdUri = New-Object System.Uri(($cwd.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar))
        $pathUri = New-Object System.Uri($path)
        return [System.Uri]::UnescapeDataString(
            $cwdUri.MakeRelativeUri($pathUri).ToString()
        ).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    }
}

function Get-LatestVisualStudioYear {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    if (Test-Path $vswhere) {
        $latestVersion = & $vswhere -latest -property installationVersion 2>$null
        if ($latestVersion -match '^(\d+)\.') {
            # Major version to year: 17 = 2022, 16 = 2019, 15 = 2017
            $major = [int]$Matches[1]
            return 2000 + $major + 5
        }
    }

    return $null
}

$hasHelpArg =
    $Args |
    Where-Object { $_ -match '^(?i)(help|-h|--help)$' } |
    Select-Object -First 1

if ($hasHelpArg) {
    Write-Usage
    exit 0
}

$withChildDirSearch = $Args.Count -gt 0

# Detect latest VS version; if 2022 or below, prefer .sln over .slnx
$vsYear = Get-LatestVisualStudioYear
$preferSlnx = ($vsYear -eq $null) -or ($vsYear -gt 2022)

if ($vsYear) {
    $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath 2>$null
    Write-Info "Detected Visual Studio $vsYear at: $vsPath"
} else {
    Write-Info "Could not detect Visual Studio version (vswhere not found), defaulting to .slnx preference."
}

$candidates = @()

# Current dir
$candidates += Get-Files ".\*.slnx"
$candidates += Get-Files ".\*.sln"

# Build dir
$candidates += Get-Files ".\build\*.slnx"
$candidates += Get-Files ".\build\*.sln"
$candidates += Get-Files ".\Everything\*.slnx"
$candidates += Get-Files ".\Everything\*.sln"

# Direct child dirs, only when a non-help arg was provided
if ($withChildDirSearch) {
    $childDirs = Get-ChildItem -Path "." -Directory -ErrorAction SilentlyContinue

    foreach ($dir in $childDirs) {
        $candidates += Get-Files (Join-Path $dir.FullName "*.slnx")
        $candidates += Get-Files (Join-Path $dir.FullName "*.sln")
    }
}

# Parent dir as last resort
$parent = Split-Path -Parent (Get-Location).Path

if ($parent) {
    $candidates += Get-Files (Join-Path $parent "*.slnx")
    $candidates += Get-Files (Join-Path $parent "*.sln")
}

# Remove duplicates and prioritize .slnx over .sln
$candidates =
    $candidates |
    Where-Object { $_ } |
    Sort-Object `
        @{ Expression = { if ($_.Extension -ieq ".slnx") { if ($preferSlnx) { 0 } else { 1 } } else { if ($preferSlnx) { 1 } else { 0 } } } }, `
        FullName `
        -Unique

if ($withChildDirSearch -and $candidates.Count -gt 1) {
    Write-Warn "Several .slnx/.sln files found:"
    foreach ($candidate in $candidates) {
        Write-Host "  $(Get-RelativePathFromCwd $candidate.FullName)"
    }

    Write-Warn ""
    Write-Warn "Not opening anything because several matches were found."
    exit 1
}

$solution = $candidates | Select-Object -First 1

if ($solution) {
    Write-Info "Opening solution:"
    Write-Info "  $($solution.FullName)"

    Start-Process $solution.FullName
}
else {
    Write-Warn "No .slnx or .sln file found in:"
    Write-Warn "  $(Get-Location)"
    Write-Warn "  $(Join-Path (Get-Location) 'build')"

    if ($withChildDirSearch) {
        Write-Warn "  direct child directories of $(Get-Location)"
    }

    if ($parent) {
        Write-Warn "  $parent"
    }
}
