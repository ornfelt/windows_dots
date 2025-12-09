param(
    [Parameter(Position = 0)]
    [string]$Language
)

# Map all aliases -> normalized language name
$languageMap = @{
    'c'          = 'c'
    'cs'         = 'csharp'
    'c#'         = 'csharp'
    'csharp'     = 'csharp'
    'cpp'        = 'cpp'
    'c++'        = 'cpp'
    'go'         = 'go'
    'golang'     = 'go'
    'java'       = 'java'
    'js'         = 'javascript'
    'javascript' = 'javascript'
    'ts'         = 'typescript'
    'typescript' = 'typescript'
    'py'         = 'python'
    'python'     = 'python'
    'rust'       = 'rust'
    'rs'         = 'rust'
}

function Show-Usage {
    Write-Host "Usage: .\copy-gitignore.ps1 <language>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available code language arguments (case-insensitive):"

    $languages = @(
        'c'
        'cs / c# / csharp'
        'cpp / c++'
        'go / golang'
        'java'
        'js / javascript'
        'ts / typescript'
        'py / python'
        'rust / rs'
    )

    foreach ($lang in $languages) {
        Write-Host "  $lang" -ForegroundColor Magenta
    }
}

function Copy-GitignoreForLanguage {
    param(
        [Parameter(Mandatory)]
        [string]$NormalizedLanguage
    )

    # Ensure env var exists
    $codeRoot = $env:code_root_dir
    if (-not $codeRoot) {
        Write-Host "Environment variable 'code_root_dir' is not set. Cannot resolve .gitignore source path." -ForegroundColor DarkYellow
        exit 1
    }

    # Relative .gitignore locations (from code_root_dir)
    $gitignoreRelativeMap = @{
        'c'          = 'Code2/General/utils/cfg/c/.gitignore'
        'cpp'        = 'Code2/General/utils/cfg/cpp/.gitignore'
        'csharp'     = 'Code2/General/utils/cfg/cs/Cfg/.gitignore'
        'go'         = 'Code2/General/utils/cfg/go/.gitignore'
        'java'       = 'Code2/General/utils/cfg/java/cfg/.gitignore'
        'javascript' = 'Code2/General/utils/cfg/js/.gitignore'
        'python'     = 'Code2/General/utils/cfg/py/.gitignore'
        'rust'       = 'Code2/General/utils/cfg/rust/cfg/.gitignore'
        'typescript' = 'Code2/General/utils/cfg/ts/.gitignore'
    }

    if (-not $gitignoreRelativeMap.ContainsKey($NormalizedLanguage)) {
        Write-Host "No .gitignore mapping defined for normalized language '$NormalizedLanguage'." -ForegroundColor DarkYellow
        exit 1
    }

    $relativePath = $gitignoreRelativeMap[$NormalizedLanguage]
    $sourcePath   = Join-Path $codeRoot $relativePath

    # Check that the source .gitignore exists
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        Write-Host "Source .gitignore not found for '$NormalizedLanguage' at:" -ForegroundColor DarkYellow
        Write-Host "  $sourcePath" -ForegroundColor DarkYellow
        exit 1
    }

    # Destination: .gitignore in current directory
    $destPath = Join-Path (Get-Location) '.gitignore'

    if (Test-Path -LiteralPath $destPath) {
        Write-Host "A .gitignore already exists in the current directory:" -ForegroundColor DarkYellow
        Write-Host "  $destPath" -ForegroundColor DarkYellow
        Write-Host "Nothing was copied." -ForegroundColor DarkYellow
        exit 1
    }

    try {
        Copy-Item -LiteralPath $sourcePath -Destination $destPath
        Write-Host "Copied .gitignore for '$NormalizedLanguage' to current directory:" -ForegroundColor Green
        Write-Host "  Source: $sourcePath" -ForegroundColor Green
        Write-Host "  Dest:   $destPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to copy .gitignore: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# If no argument: show usage/help and exit
if (-not $Language) {
    Show-Usage
    exit 0
}

# Normalize & validate arg
$key = $Language.Trim().ToLower()
if (-not $languageMap.ContainsKey($key)) {
    Write-Host "Unknown code language argument: '$Language'" -ForegroundColor Red
    Write-Host ""
    Show-Usage
    exit 1
}

$normalizedLanguage = $languageMap[$key]

Write-Host "Selected code language: " -NoNewline
Write-Host $normalizedLanguage -ForegroundColor Magenta

# Do the .gitignore copy
Copy-GitignoreForLanguage -NormalizedLanguage $normalizedLanguage

