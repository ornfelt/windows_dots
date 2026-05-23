param(
    [Parameter(Position=0)]
    [string]$Arg,

    [Parameter(Position=1)]
    [string]$Arg2
)

# cmake.ps1 - data-driven cmake helper.
#
# Patterns are loaded from:  $Env:my_notes_path/scripts/cmake_patterns.json
#
# Usage:
#   .\cmake.ps1                 detect path and RUN the chosen cmake
#   .\cmake.ps1 onlyprint       detect path and PRINT commands (no execution)
#   .\cmake.ps1 r | release     RUN in Release mode
#   .\cmake.ps1 r foo           Release mode and PRINT-ONLY
#   .\cmake.ps1 rd | rwdi       RUN in RelWithDebInfo mode
#   .\cmake.ps1 h | --help      show help

# ---------- Help ----------
function Show-Help {
@"
cmake.ps1 - data-driven cmake helper

Usage:
  .\cmake.ps1
      Detect path, pick a pattern, RUN the cmake command.

  .\cmake.ps1 onlyprint
      Detect path, pick a pattern, PRINT commands only.

  .\cmake.ps1 r | release
      Run in Release mode (sets BuildType=Release).

  .\cmake.ps1 r foo
      Release mode + PRINT-ONLY (any second arg flips to print-only).

  .\cmake.ps1 rd | rwdi | relwithdebinfo
      Run in RelWithDebInfo mode.

  .\cmake.ps1 h | help | -h | --help
      Show this help.

Notes:
  - BuildType defaults to Debug unless r/release or rd/rwdi is passed.
  - The script picks a cmake template based on the current working directory
    by matching keywords from cmake_patterns.json (ordered substring match,
    case-insensitive).
  - The cmake invocation prefix is auto-detected:
        ./CMakeLists.txt  -> 'cmake -B build -S . ...'
        ../CMakeLists.txt -> 'cmake .. ...'
        neither           -> warn + force PRINT-ONLY
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

# ---------- Arg parsing (same behavior as before) ----------
$OnlyPrint      = $null
$Release        = $false
$RelWithDebInfo = $false

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
    else {
        $OnlyPrint = 'true'
    }

    Write-Host "If needed, run:" -ForegroundColor Blue
    Write-Host 'make -j$([Environment]::ProcessorCount)' -ForegroundColor Blue
    Write-Output ""
}

$BuildType = 'Debug'
if     ($Release)        { $BuildType = 'Release' }
elseif ($RelWithDebInfo) { $BuildType = 'RelWithDebInfo' }

if ($OnlyPrint) {
    Write-Host ("[OnlyPrint]=ON  [BuildType]={0}" -f $BuildType) -ForegroundColor Magenta
} else {
    Write-Host ("[OnlyPrint]=OFF  [BuildType]={0}" -f $BuildType) -ForegroundColor Magenta
}

# ---------- vcpkg toolchain paths (hard-coded) ----------
$vcpkgPrimary   = "$Env:code_root_dir/C++/diablo_devilutionX/vcpkg/scripts/buildsystems/vcpkg.cmake"
$vcpkgSecondary = 'C:/local/bin/vcpkg/scripts/buildsystems/vcpkg.cmake'

function Get-VcpkgPath {
    if (Test-Path -LiteralPath $vcpkgPrimary)   { return $vcpkgPrimary }
    if (Test-Path -LiteralPath $vcpkgSecondary) { return $vcpkgSecondary }
    return $null
}

# ---------- Load patterns JSON ----------
$notesPath = $Env:my_notes_path
if ([string]::IsNullOrWhiteSpace($notesPath)) {
    $notesPath = $PSScriptRoot
    Write-Host "Warning: `$Env:my_notes_path is not set. Falling back to script directory: $notesPath" -ForegroundColor Yellow
}
$patternsFile = Join-Path $notesPath 'scripts/cmake_patterns.json'

if (-not (Test-Path -LiteralPath $patternsFile)) {
    Write-Host "Patterns file not found: $patternsFile" -ForegroundColor Red
    exit 1
}

try {
    $config = Get-Content -Raw -LiteralPath $patternsFile | ConvertFrom-Json
} catch {
    Write-Host "Failed to parse $patternsFile : $_" -ForegroundColor Red
    exit 1
}

# ---------- Path matching ----------
$cwd      = (Get-Location).Path
$cwdLower = $cwd.ToLower()

function Test-PathContainsInOrder {
    param([string[]]$keywords)
    if ($null -eq $keywords -or $keywords.Count -eq 0) { return $false }
    $pos = 0
    foreach ($kw in $keywords) {
        $idx = $cwdLower.IndexOf($kw.ToLower(), $pos)
        if ($idx -lt 0) { return $false }
        $pos = $idx + $kw.Length
    }
    return $true
}

function Test-PatternMatches {
    param($pattern)
    $kw = $pattern.keywords
    if ($null -eq $kw -or $kw.Count -eq 0) { return $false }

    # Single group: array of strings.   Multi-group: array of arrays.
    if ($kw[0] -is [string]) {
        return Test-PathContainsInOrder $kw
    }
    foreach ($group in $kw) {
        if (Test-PathContainsInOrder $group) { return $true }
    }
    return $false
}

# ---------- CMake prefix auto-detection ----------
function Detect-CMakePrefix {
    if (Test-Path -LiteralPath './CMakeLists.txt') {
        return @{ Prefix = 'cmake -B build -S .'; Location = 'current' }
    }
    if (Test-Path -LiteralPath '../CMakeLists.txt') {
        return @{ Prefix = 'cmake ..';            Location = 'parent'  }
    }
    return @{ Prefix = $null; Location = 'none' }
}

function Ensure-CMakeDetected {
    param([string]$Context)
    $d = Detect-CMakePrefix
    if ($d.Location -eq 'none') {
        $label = if ([string]::IsNullOrWhiteSpace($Context)) { 'this project' } else { $Context }
        Write-Host ""
        Write-Host "CMakeLists.txt not found in current or parent directory - $label" -ForegroundColor Yellow
        exit 1
    }
    return $d
}

# ---------- Substitution & flag formatting ----------
function Substitute-Tokens {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    $r = $Value -replace '@BuildType', $BuildType
    $r = $r     -replace '\{NPROC\}',  ([string][Environment]::ProcessorCount)
    return $r
}

function Get-MergedFlags {
    # Returns an [ordered] hashtable: base + toggles (toggles override).
    param($base, $toggles)
    $merged = [ordered]@{}
    if ($null -ne $base) {
        foreach ($p in $base.PSObject.Properties) {
            $merged[$p.Name] = $p.Value
        }
    }
    if ($null -ne $toggles) {
        foreach ($p in $toggles.PSObject.Properties) {
            $merged[$p.Name] = $p.Value
        }
    }
    return $merged
}

function Convert-FlagsToString {
    param($flagsOrderedDict)
    $parts = @()
    foreach ($key in $flagsOrderedDict.Keys) {
        $val = Substitute-Tokens ([string]$flagsOrderedDict[$key])
        $parts += "-D$key=$val"
    }
    return ($parts -join ' ')
}

function Run-Or-Print {
    param([string]$Cmd)
    if ($OnlyPrint) {
        Write-Host $Cmd -ForegroundColor Cyan
    } else {
        Write-Host "Executing: $Cmd" -ForegroundColor Cyan
        Invoke-Expression $Cmd
    }
}

function Print-OnlyPrintExtras {
    param($extras)
    if (-not $OnlyPrint -or $null -eq $extras) { return }
    foreach ($extra in $extras) {
        Write-Output ""
        if ($extra.PSObject.Properties.Name -contains 'label' -and $extra.label) {
            Write-Output $extra.label
        }
        if ($extra.PSObject.Properties.Name -contains 'command' -and $extra.command) {
            Write-Output (Substitute-Tokens $extra.command)
        }
        if ($extra.PSObject.Properties.Name -contains 'lines' -and $extra.lines) {
            foreach ($l in $extra.lines) { Write-Output (Substitute-Tokens $l) }
        }
    }
}

# ---------- Per-pattern dispatch ----------
function Invoke-Pattern {
    param($pattern)

    $ctx = if ($pattern.context_name) { $pattern.context_name } else { 'pattern' }

    # 1) Instructions-only entries (e.g. neovim)
    if ($pattern.PSObject.Properties.Name -contains 'instructions' -and $null -ne $pattern.instructions) {
        foreach ($line in $pattern.instructions) {
            Write-Output (Substitute-Tokens $line)
        }
        if ($pattern.PSObject.Properties.Name -contains 'only_print_extras') {
            Print-OnlyPrintExtras $pattern.only_print_extras
        }
        return
    }

    # 2) Custom-command entries (e.g. ioq3, ollama, dhewm3, llama.cpp)
    if ($pattern.PSObject.Properties.Name -contains 'custom_command' `
        -and -not [string]::IsNullOrWhiteSpace($pattern.custom_command)) {

        # Still warn if no CMakeLists is around (best-effort, doesn't change command)
        $null = Ensure-CMakeDetected -Context $ctx

        $cmd = Substitute-Tokens $pattern.custom_command
        Run-Or-Print $cmd

        if ($pattern.PSObject.Properties.Name -contains 'only_print_extras') {
            Print-OnlyPrintExtras $pattern.only_print_extras
        }
        return
    }

    # 3) Standard base_flags + variants pattern
    $detect = Ensure-CMakeDetected -Context $ctx
    $cmakePrefix = $detect.Prefix

    $baseFlags = $pattern.base_flags  # PSCustomObject or $null

    # vcpkg alternative (always printed, before main, in DarkBlue)
    if ($pattern.PSObject.Properties.Name -contains 'vcpkg_support' -and $pattern.vcpkg_support -eq $true) {
        Write-Output ""
        Write-Host "alternative cmake with vcpkg:" -ForegroundColor DarkBlue
        $vcpkgPath = Get-VcpkgPath
        if ($null -ne $vcpkgPath) {
            $vcFlags = Get-MergedFlags $baseFlags $null
            if ($vcFlags.Contains('USE_VCPKG')) { $vcFlags['USE_VCPKG'] = 'ON' }
            $vcStr = Convert-FlagsToString $vcFlags
            Write-Host "$cmakePrefix -DCMAKE_TOOLCHAIN_FILE=`"$vcpkgPath`" $vcStr" -ForegroundColor DarkBlue
        } else {
            Write-Host "(no vcpkg toolchain found at expected paths)" -ForegroundColor DarkBlue
            $vcFlags = Get-MergedFlags $baseFlags $null
            if ($vcFlags.Contains('USE_VCPKG')) { $vcFlags['USE_VCPKG'] = 'ON' }
            $vcStr = Convert-FlagsToString $vcFlags
            Write-Host "$cmakePrefix -DCMAKE_TOOLCHAIN_FILE=`"C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake`" $vcStr" -ForegroundColor DarkBlue
        }
        Write-Output ""
    }

    # Main command
    $mainFlags    = Get-MergedFlags $baseFlags $null
    $mainFlagsStr = Convert-FlagsToString $mainFlags
    if ([string]::IsNullOrWhiteSpace($mainFlagsStr)) {
        $main = $cmakePrefix
    } else {
        $main = "$cmakePrefix $mainFlagsStr"
    }
    Run-Or-Print $main

    # Variants (OnlyPrint only)
    if ($OnlyPrint `
        -and $pattern.PSObject.Properties.Name -contains 'variants' `
        -and $null -ne $pattern.variants -and $pattern.variants.Count -gt 0) {

        Write-Output ""
        Write-Output "alternative cmake commands:"
        foreach ($variant in $pattern.variants) {
            Write-Output ""
            if ($variant.label) { Write-Output ("{0}:" -f $variant.label) }
            $vFlags = Get-MergedFlags $baseFlags $variant.toggles
            $vStr   = Convert-FlagsToString $vFlags
            if ([string]::IsNullOrWhiteSpace($vStr)) {
                Write-Output $cmakePrefix
            } else {
                Write-Output "$cmakePrefix $vStr"
            }
        }
    }

    # only_print_extras
    if ($pattern.PSObject.Properties.Name -contains 'only_print_extras') {
        Print-OnlyPrintExtras $pattern.only_print_extras
    }
}

# ---------- Main loop ----------
$matched = $false
foreach ($pattern in $config.patterns) {
    if (Test-PatternMatches $pattern) {
        Invoke-Pattern $pattern
        $matched = $true
        break
    }
}

if (-not $matched) {
    $detect = Ensure-CMakeDetected -Context (Split-Path -Leaf $cwd)
    Write-Host "No cmake pattern found for: $cwd" -ForegroundColor DarkYellow
    Write-Host "Using default cmake command..." -ForegroundColor DarkYellow
    $main = "$($detect.Prefix) -DCMAKE_BUILD_TYPE=$BuildType"
    Run-Or-Print $main
}
