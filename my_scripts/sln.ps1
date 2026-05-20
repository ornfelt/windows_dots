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
    Write-Host "  Opens the first .sln/.slnx found in current dir, build dir, or parent dir."
    Write-Host ""
    Write-Host "With any non-help arg:"
    Write-Host "  Also checks direct child dirs for .sln/.slnx files."
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

$hasHelpArg =
    $Args |
    Where-Object { $_ -match '^(?i)(help|-h|--help)$' } |
    Select-Object -First 1

if ($hasHelpArg) {
    Write-Usage
    exit 0
}

$withChildDirSearch = $Args.Count -gt 0

$candidates = @()

# Current dir
$candidates += Get-Files ".\*.sln"
$candidates += Get-Files ".\*.slnx"

# Build dir
$candidates += Get-Files ".\build\*.sln"
$candidates += Get-Files ".\build\*.slnx"
$candidates += Get-Files ".\Everything\*.sln"
$candidates += Get-Files ".\Everything\*.slnx"

# Direct child dirs, only when a non-help arg was provided
if ($withChildDirSearch) {
    $childDirs = Get-ChildItem -Path "." -Directory -ErrorAction SilentlyContinue

    foreach ($dir in $childDirs) {
        $candidates += Get-Files (Join-Path $dir.FullName "*.sln")
        $candidates += Get-Files (Join-Path $dir.FullName "*.slnx")
    }
}

# Parent dir as last resort
$parent = Split-Path -Parent (Get-Location).Path

if ($parent) {
    $candidates += Get-Files (Join-Path $parent "*.sln")
    $candidates += Get-Files (Join-Path $parent "*.slnx")
}

# Remove duplicates, keep first occurrence order
$candidates =
    $candidates |
    Where-Object { $_ } |
    Sort-Object FullName -Unique

if ($withChildDirSearch -and $candidates.Count -gt 1) {
    Write-Warn "Several .sln/.slnx files found:"
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
    Write-Warn "No .sln or .slnx file found in:"
    Write-Warn "  $(Get-Location)"
    Write-Warn "  $(Join-Path (Get-Location) 'build')"

    if ($withChildDirSearch) {
        Write-Warn "  direct child directories of $(Get-Location)"
    }

    if ($parent) {
        Write-Warn "  $parent"
    }
}
