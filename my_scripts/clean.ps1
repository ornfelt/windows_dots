<#
.SYNOPSIS
    Clean build artifacts for various programming languages.
.DESCRIPTION
    Recursively removes compiled files, build directories, and caches
    for C, C++, C#, Go, Java, JavaScript, TypeScript, Python, and Rust.
.EXAMPLE
    .\clean.ps1 cs
    .\clean.ps1 rust -GitRoot
    .\clean.ps1 java -Path C:\projects\app
    .\clean.ps1 cpp -NoRecurse
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Language = '',

    [string]$Path = '',

    [switch]$NoRecurse,

    [switch]$GitRoot
)

Set-StrictMode -Version Latest

# -- Color helpers -------------------------------------------------------------

function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err     ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt ([string]$m) { Write-Host $m -ForegroundColor Magenta }

function Confirm-Action ([string]$prompt) {
    Write-Host "$prompt " -ForegroundColor DarkYellow -NoNewline
    Write-Host '[y/N] ' -NoNewline
    $r = Read-Host
    return ($r.Trim() -match '^(y|yes)$')
}

# -- Language map --------------------------------------------------------------

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

# -- Help ----------------------------------------------------------------------

function Show-Help {
    Write-Info 'clean.ps1 - Remove build artifacts for various programming languages'
    Write-Host ''
    Write-Info 'USAGE'
    Write-Host '  .\clean.ps1 LANGUAGE [-Path DIR] [-NoRecurse] [-GitRoot]'
    Write-Host ''
    Write-Info 'LANGUAGES'
    Write-Host '  c                       C       (.o .obj .out .a build/)'
    Write-Host '  cs | c# | csharp       C#      (bin/ obj/)'
    Write-Host '  cpp | c++              C++     (.o .obj .out .a build/)'
    Write-Host '  go | golang            Go      (go clean caches)'
    Write-Host '  java                   Java    (.class target/ build/)'
    Write-Host '  js | javascript        JS      (dist/ node_modules/)'
    Write-Host '  ts | typescript        TS      (dist/ .tsbuildinfo node_modules/)'
    Write-Host '  py | python            Python  (__pycache__/ .pyc dist/)'
    Write-Host '  rust | rs              Rust    (target/)'
    Write-Host ''
    Write-Info 'OPTIONS'
    Write-Host '  -Path DIR      Use the specified directory instead of the current one'
    Write-Host '  -NoRecurse     Only clean in the target directory (skip subdirectories)'
    Write-Host '  -GitRoot       Use the git repository root as the working directory'
    Write-Host ''
    Write-Info 'EXAMPLES'
    Write-Host '  .\clean.ps1 cs                             # Clean C# from cwd recursively'
    Write-Host '  .\clean.ps1 rust -GitRoot                  # Clean Rust from repo root'
    Write-Host '  .\clean.ps1 java -Path C:\projects\app     # Clean Java in specified dir'
    Write-Host '  .\clean.ps1 cpp -NoRecurse                 # Clean C++ (current dir only)'
    Write-Host '  .\clean.ps1 js                             # Clean JS artifacts + optional node_modules'
    Write-Host '  .\clean.ps1 -h                             # Show this help'
}

# -- Removal helpers -----------------------------------------------------------

function Remove-MatchingDirs {
    param(
        [string]$BasePath,
        [string[]]$Names,
        [bool]$Recurse,
        [switch]$AskConfirm,
        [string]$ConfirmMsg = ''
    )

    $gci = @{ Path = $BasePath; Directory = $true; ErrorAction = 'SilentlyContinue' }
    if ($Recurse) { $gci['Recurse'] = $true }

    $dirs = @(Get-ChildItem @gci | Where-Object { $Names -contains $_.Name })

    if ($dirs.Count -eq 0) {
        $label = $Names -join ', '
        Write-Info "  No directories found matching: $label"
        return
    }

    foreach ($d in $dirs) { Write-Host "    Found: $($d.FullName)" -ForegroundColor Gray }

    if ($AskConfirm) {
        $msg = if ($ConfirmMsg) { $ConfirmMsg } else { "Delete $($dirs.Count) director(y/ies)?" }
        if (-not (Confirm-Action "  $msg")) {
            Write-Warn '  Skipped.'
            return
        }
    }

    $count = 0
    foreach ($d in $dirs) {
        try {
            Remove-Item -Path $d.FullName -Recurse -Force -ErrorAction Stop
            Write-Ok "  Deleted: $($d.FullName)"
            $count++
        }
        catch {
            Write-Err "  Failed to delete: $($d.FullName) - $_"
        }
    }
    if ($count -gt 0) { Write-Info "  Removed $count director(y/ies)." }
}

function Remove-MatchingFiles {
    param(
        [string]$BasePath,
        [string[]]$Extensions,
        [bool]$Recurse
    )

    $gci = @{ Path = $BasePath; File = $true; ErrorAction = 'SilentlyContinue' }
    if ($Recurse) { $gci['Recurse'] = $true }

    $files = @(Get-ChildItem @gci | Where-Object { $Extensions -contains $_.Extension.ToLower() })

    if ($files.Count -eq 0) {
        $label = $Extensions -join ', '
        Write-Info "  No files found matching: $label"
        return
    }

    $count = 0
    foreach ($f in $files) {
        try {
            Remove-Item -Path $f.FullName -Force -ErrorAction Stop
            Write-Ok "  Deleted: $($f.FullName)"
            $count++
        }
        catch {
            Write-Err "  Failed to delete: $($f.FullName) - $_"
        }
    }
    if ($count -gt 0) { Write-Info "  Removed $count file(s)." }
}

function Remove-DirsBySuffix {
    param(
        [string]$BasePath,
        [string]$Suffix,
        [bool]$Recurse
    )

    $gci = @{ Path = $BasePath; Directory = $true; ErrorAction = 'SilentlyContinue' }
    if ($Recurse) { $gci['Recurse'] = $true }

    $dirs = @(Get-ChildItem @gci | Where-Object { $_.Name.EndsWith($Suffix) })

    if ($dirs.Count -eq 0) { return }

    $count = 0
    foreach ($d in $dirs) {
        try {
            Remove-Item -Path $d.FullName -Recurse -Force -ErrorAction Stop
            Write-Ok "  Deleted: $($d.FullName)"
            $count++
        }
        catch {
            Write-Err "  Failed to delete: $($d.FullName) - $_"
        }
    }
    if ($count -gt 0) { Write-Info "  Removed $count '*$Suffix' director(y/ies)." }
}

function Run-CleanCommand {
    param(
        [string]$BasePath,
        [string]$Exe,
        [string[]]$ExeArgs,
        [string]$Description
    )

    $display = ("$Exe " + ($ExeArgs -join ' ')).Trim()

    if (-not (Confirm-Action "  Run '$display' ($Description)?")) { return }

    Write-Info "  Running: $display"
    Push-Location $BasePath
    try {
        & $Exe @ExeArgs 2>&1 | ForEach-Object { Write-Host "    $_" }
        Write-Ok "  $display completed."
    }
    catch {
        Write-Err "  $display failed: $_"
    }
    finally { Pop-Location }
}

# -- Language cleaners ---------------------------------------------------------

function Clean-C {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning C artifacts --'

    Write-Info '  Removing compiled object / binary files...'
    Remove-MatchingFiles -BasePath $BasePath -Recurse $Recurse `
        -Extensions @('.o', '.obj', '.out', '.a', '.so', '.dylib', '.dll', '.lib', '.exe', '.pdb', '.d', '.gch')

    Write-Info '  Checking for build/ directory...'
    Remove-MatchingDirs -BasePath $BasePath -Names @('build') -Recurse $Recurse `
        -AskConfirm -ConfirmMsg "Delete 'build' director(y/ies)?"

    if (Test-Path (Join-Path $BasePath 'Makefile')) {
        Run-CleanCommand $BasePath 'make' @('clean') 'run Makefile clean target'
    }
}

function Clean-Cpp {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning C++ artifacts --'

    Write-Info '  Removing compiled object / binary files...'
    Remove-MatchingFiles -BasePath $BasePath -Recurse $Recurse `
        -Extensions @('.o', '.obj', '.out', '.a', '.so', '.dylib', '.dll', '.lib', '.exe', '.pdb', '.d', '.gch', '.pch')

    Write-Info '  Checking for build/ directory...'
    Remove-MatchingDirs -BasePath $BasePath -Names @('build') -Recurse $Recurse `
        -AskConfirm -ConfirmMsg "Delete 'build' director(y/ies)?"

    $hasMakefile = Test-Path (Join-Path $BasePath 'Makefile')
    $hasCMake    = Test-Path (Join-Path $BasePath 'CMakeLists.txt')

    if ($hasMakefile) {
        Run-CleanCommand $BasePath 'make' @('clean') 'run Makefile clean target'
    }
    if ($hasCMake -and -not $hasMakefile) {
        Run-CleanCommand $BasePath 'cmake' @('--build', 'build', '--target', 'clean') 'cmake build clean'
    }
}

function Clean-CSharp {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning C# artifacts --'

    Write-Info '  Removing bin/ and obj/ directories...'
    Remove-MatchingDirs -BasePath $BasePath -Names @('bin', 'obj') -Recurse $Recurse

    $hasSln    = @(Get-ChildItem -Path $BasePath -Filter '*.sln'    -File -ErrorAction SilentlyContinue).Count -gt 0
    $hasCsproj = @(Get-ChildItem -Path $BasePath -Filter '*.csproj' -File -ErrorAction SilentlyContinue).Count -gt 0
    if ($hasSln -or $hasCsproj) {
        Run-CleanCommand $BasePath 'dotnet' @('clean') 'dotnet SDK clean'
    }
}

function Clean-Go {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning Go artifacts --'

    Write-Info '  Removing compiled binaries...'
    Remove-MatchingFiles -BasePath $BasePath -Extensions @('.exe', '.test') -Recurse $Recurse

    $hasGoMod = Test-Path (Join-Path $BasePath 'go.mod')
    if ($hasGoMod) {
        Run-CleanCommand $BasePath 'go' @('clean') 'remove object files and cached binaries'
    }

    Run-CleanCommand $BasePath 'go' @('clean', '-cache')     'clear build cache'
    Run-CleanCommand $BasePath 'go' @('clean', '-testcache') 'clear test cache'
}

function Clean-Java {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning Java artifacts --'

    Write-Info '  Removing .class files...'
    Remove-MatchingFiles -BasePath $BasePath -Extensions @('.class') -Recurse $Recurse

    Write-Info '  Removing build output directories (target/ build/ out/)...'
    Remove-MatchingDirs -BasePath $BasePath -Names @('target', 'build', 'out') -Recurse $Recurse

    # Maven
    if (Test-Path (Join-Path $BasePath 'pom.xml')) {
        Run-CleanCommand $BasePath 'mvn' @('clean') 'Maven clean'
    }

    # Gradle
    $hasGradle    = Test-Path (Join-Path $BasePath 'build.gradle')
    $hasGradleKts = Test-Path (Join-Path $BasePath 'build.gradle.kts')
    if ($hasGradle -or $hasGradleKts) {
        $gradlew = Join-Path $BasePath 'gradlew.bat'
        if (Test-Path $gradlew) {
            Run-CleanCommand $BasePath $gradlew @('clean') 'Gradle wrapper clean'
        }
        else {
            Run-CleanCommand $BasePath 'gradle' @('clean') 'Gradle clean'
        }
    }
}

function Clean-JavaScript {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning JavaScript artifacts --'

    Write-Info '  Removing build output directories...'
    Remove-MatchingDirs -BasePath $BasePath -Recurse $Recurse `
        -Names @('dist', '.cache', '.parcel-cache', '.next', '.nuxt', '.output', '.turbo', 'coverage', '.nyc_output')

    # node_modules (ask)
    Write-Info '  Checking for package directories...'
    $gci = @{ Path = $BasePath; Directory = $true; ErrorAction = 'SilentlyContinue' }
    if ($Recurse) { $gci['Recurse'] = $true }
    $nmDirs = @(Get-ChildItem @gci | Where-Object { $_.Name -eq 'node_modules' })

    if ($nmDirs.Count -gt 0) {
        foreach ($d in $nmDirs) { Write-Host "    Found: $($d.FullName)" -ForegroundColor Gray }
        if (Confirm-Action "  Delete $($nmDirs.Count) node_modules director(y/ies)?") {
            $count = 0
            foreach ($d in $nmDirs) {
                try {
                    Remove-Item -Path $d.FullName -Recurse -Force -ErrorAction Stop
                    Write-Ok "  Deleted: $($d.FullName)"
                    $count++
                }
                catch { Write-Err "  Failed: $($d.FullName) - $_" }
            }
            if ($count -gt 0) { Write-Info "  Removed $count node_modules director(y/ies)." }
        }
        else { Write-Warn '  Skipped node_modules.' }
    }
    else {
        Write-Info '  No node_modules directories found.'
    }

    # Detect package manager and offer cache clean
    $pm = 'npm'
    if     (Test-Path (Join-Path $BasePath 'yarn.lock'))      { $pm = 'yarn' }
    elseif (Test-Path (Join-Path $BasePath 'pnpm-lock.yaml')) { $pm = 'pnpm' }

    switch ($pm) {
        'npm'  { Run-CleanCommand $BasePath 'npm'  @('cache', 'clean', '--force') 'clear npm cache' }
        'yarn' { Run-CleanCommand $BasePath 'yarn' @('cache', 'clean')            'clear yarn cache' }
        'pnpm' { Run-CleanCommand $BasePath 'pnpm' @('store', 'prune')            'prune pnpm store' }
    }
}

function Clean-TypeScript {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning TypeScript artifacts --'

    Write-Info '  Removing build output directories...'
    Remove-MatchingDirs -BasePath $BasePath -Recurse $Recurse `
        -Names @('dist', 'out', '.cache', '.parcel-cache', '.next', '.nuxt', '.output', '.turbo', 'coverage', '.nyc_output')

    Write-Info '  Removing .tsbuildinfo files...'
    Remove-MatchingFiles -BasePath $BasePath -Extensions @('.tsbuildinfo') -Recurse $Recurse

    # node_modules (ask)
    Write-Info '  Checking for package directories...'
    $gci = @{ Path = $BasePath; Directory = $true; ErrorAction = 'SilentlyContinue' }
    if ($Recurse) { $gci['Recurse'] = $true }
    $nmDirs = @(Get-ChildItem @gci | Where-Object { $_.Name -eq 'node_modules' })

    if ($nmDirs.Count -gt 0) {
        foreach ($d in $nmDirs) { Write-Host "    Found: $($d.FullName)" -ForegroundColor Gray }
        if (Confirm-Action "  Delete $($nmDirs.Count) node_modules director(y/ies)?") {
            $count = 0
            foreach ($d in $nmDirs) {
                try {
                    Remove-Item -Path $d.FullName -Recurse -Force -ErrorAction Stop
                    Write-Ok "  Deleted: $($d.FullName)"
                    $count++
                }
                catch { Write-Err "  Failed: $($d.FullName) - $_" }
            }
            if ($count -gt 0) { Write-Info "  Removed $count node_modules director(y/ies)." }
        }
        else { Write-Warn '  Skipped node_modules.' }
    }
    else {
        Write-Info '  No node_modules directories found.'
    }

    # Detect package manager and offer cache clean
    $pm = 'npm'
    if     (Test-Path (Join-Path $BasePath 'yarn.lock'))      { $pm = 'yarn' }
    elseif (Test-Path (Join-Path $BasePath 'pnpm-lock.yaml')) { $pm = 'pnpm' }

    switch ($pm) {
        'npm'  { Run-CleanCommand $BasePath 'npm'  @('cache', 'clean', '--force') 'clear npm cache' }
        'yarn' { Run-CleanCommand $BasePath 'yarn' @('cache', 'clean')            'clear yarn cache' }
        'pnpm' { Run-CleanCommand $BasePath 'pnpm' @('store', 'prune')            'prune pnpm store' }
    }
}

function Clean-Python {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning Python artifacts --'

    Write-Info '  Removing .pyc / .pyo files...'
    Remove-MatchingFiles -BasePath $BasePath -Extensions @('.pyc', '.pyo') -Recurse $Recurse

    Write-Info '  Removing cache and build directories...'
    Remove-MatchingDirs -BasePath $BasePath -Recurse $Recurse `
        -Names @('__pycache__', '.pytest_cache', '.mypy_cache', '.ruff_cache', '.tox', 'htmlcov',
                 'dist', 'build', '.eggs')

    Write-Info '  Removing *.egg-info directories...'
    Remove-DirsBySuffix -BasePath $BasePath -Suffix '.egg-info' -Recurse $Recurse

    Write-Info '  Removing .coverage files...'
    Remove-MatchingFiles -BasePath $BasePath -Extensions @('.coverage') -Recurse $Recurse

    Run-CleanCommand $BasePath 'pip' @('cache', 'purge') 'clear pip download cache'
}

function Clean-Rust {
    param([string]$BasePath, [bool]$Recurse)

    Write-InfoAlt '-- Cleaning Rust artifacts --'

    Write-Info '  Removing target/ directories...'
    Remove-MatchingDirs -BasePath $BasePath -Names @('target') -Recurse $Recurse

    if (Test-Path (Join-Path $BasePath 'Cargo.toml')) {
        Run-CleanCommand $BasePath 'cargo' @('clean') 'cargo clean'
    }
}

# ==============================================================================
# MAIN
# ==============================================================================

# -- 1. Help check -------------------------------------------------------------

$langKey = $Language.ToLower().Trim()

if (-not $Language -or $langKey -in @('help', '--help', '-h')) {
    Show-Help
    exit 0
}

if (-not $languageMap.ContainsKey($langKey)) {
    Write-Err "Unknown language: '$Language'"
    Write-Host ''
    Show-Help
    exit 1
}

$lang = $languageMap[$langKey]

# -- 2. Resolve working directory ----------------------------------------------

if ($Path -and $GitRoot) {
    Write-Err 'Cannot use both -Path and -GitRoot at the same time.'
    exit 1
}

if ($GitRoot) {
    try {
        $root = (git rev-parse --show-toplevel 2>&1).Trim()
        if ($LASTEXITCODE -ne 0) { throw $root }
        $workDir = $root
    }
    catch {
        Write-Err 'Not inside a git repository. Cannot use -GitRoot.'
        exit 1
    }
}
elseif ($Path) {
    if (-not (Test-Path $Path -PathType Container)) {
        Write-Err "Path does not exist or is not a directory: $Path"
        exit 1
    }
    $workDir = (Resolve-Path $Path).Path
}
else {
    $workDir = (Get-Location).Path
}

# -- 3. Git-repo safety check -------------------------------------------------

$recurse = -not $NoRecurse

if ($recurse) {
    $inGitRepo = $false
    Push-Location $workDir
    try {
        git rev-parse --is-inside-work-tree 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $inGitRepo = $true }
    }
    catch { }
    finally { Pop-Location }

    if (-not $inGitRepo) {
        Write-Warn "WARNING: '$workDir' is not inside a git repository."
        if (-not (Confirm-Action '  Proceed with recursive cleanup?')) {
            Write-Warn 'Aborted.'
            exit 0
        }
    }
}

# -- 4. Run language cleaner ---------------------------------------------------

Write-Host ''
Write-InfoAlt "Language : $lang"
Write-InfoAlt "Directory: $workDir"
Write-InfoAlt "Recursive: $recurse"
Write-Host ''

switch ($lang) {
    'c'          { Clean-C          -BasePath $workDir -Recurse $recurse }
    'csharp'     { Clean-CSharp     -BasePath $workDir -Recurse $recurse }
    'cpp'        { Clean-Cpp        -BasePath $workDir -Recurse $recurse }
    'go'         { Clean-Go         -BasePath $workDir -Recurse $recurse }
    'java'       { Clean-Java       -BasePath $workDir -Recurse $recurse }
    'javascript' { Clean-JavaScript -BasePath $workDir -Recurse $recurse }
    'typescript' { Clean-TypeScript -BasePath $workDir -Recurse $recurse }
    'python'     { Clean-Python     -BasePath $workDir -Recurse $recurse }
    'rust'       { Clean-Rust       -BasePath $workDir -Recurse $recurse }
}

Write-Host ''
Write-Ok 'Cleanup complete.'
