param(
    [string]$Arg = "",
    [string]$Arg2 = ""
)

# Usage:
# .\cmake.ps1            # detect path and RUN the chosen cmake
# .\cmake.ps1 onlyprint  # detect path and PRINT commands (no execution)
# .\cmake.ps1 r/release  # RUN in Release mode
# .\cmake.ps1 r foo      # RUN in Release mode and PRINT commands (no execution)
# .\cmake.ps1 rd         # RUN in RelWithDebInfo mode
# .\cmake.ps1 rwdi foo   # RUN in RelWithDebInfo mode and PRINT commands
#
# Project definitions live in $Env:my_notes_path\scripts\cmake-projects.json
# (shared with cmake.sh).

# Help check (case-insensitive)
$helpTokens = @("h", "help", "-h", "--help")
if ($helpTokens -contains $Arg.ToLower() -or $helpTokens -contains $Arg2.ToLower()) {
    @"
cmake.ps1 - context-aware cmake helper

Usage:
  .\cmake.ps1
      Detect path and RUN the chosen cmake command.

  .\cmake.ps1 onlyprint
      Detect path and PRINT commands (no execution).

  .\cmake.ps1 r | release
      Run in Release mode.

  .\cmake.ps1 r foo
      Release mode + PRINT-ONLY (because a second arg exists).

  .\cmake.ps1 rd | rwdi | relwithdebinfo
      Run in RelWithDebInfo mode.

  .\cmake.ps1 h | help | -h | --help
      Show this help.

Notes:
  - BuildType defaults to Debug unless you pass r/release.
  - Project definitions live in:
      `$Env:my_notes_path\scripts\cmake-projects.json
"@ | Write-Output
    exit 0
}

# Print-only unless argument is "r" or "release" (case-insensitive)
$OnlyPrint = $null
$Release = $null
$RelWithDebInfo = $null
$argLc = $Arg.ToLower()

if ($Arg) {
    if ($argLc -eq "r" -or $argLc -eq "release") {
        $Release = $true
        if ($Arg2) { $OnlyPrint = $true }
    }
    elseif ($argLc -eq "rwdi" -or $argLc -eq "rd" -or $argLc -eq "relwithdebinfo") {
        $RelWithDebInfo = $true
        if ($Arg2) { $OnlyPrint = $true }
    }
    else {
        $OnlyPrint = $true
    }

    Write-Host "If needed, run:" -ForegroundColor Blue
    Write-Host "make -j`$(nproc)" -ForegroundColor Blue
    Write-Output ""
}

# build type helper
$BuildType = "Debug"
if ($Release)        { $BuildType = "Release" }
if ($RelWithDebInfo) { $BuildType = "RelWithDebInfo" }

# Debug print
if ($OnlyPrint) {
    Write-Host "[OnlyPrint]=ON  [BuildType]=$BuildType"  -ForegroundColor Magenta
} else {
    Write-Host "[OnlyPrint]=OFF  [BuildType]=$BuildType" -ForegroundColor Magenta
}

# get current working dir
$cwd = (Get-Location).Path
$lc = $cwd.ToLower()

function Run-Or-Print($cmd) {
    if ($OnlyPrint) {
        Write-Host $cmd -ForegroundColor Cyan
    } else {
        Write-Host "Executing: $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd
    }
}

function Print-Alternatives($alts) {
    if ($OnlyPrint -and $alts.Count -gt 0) {
        Write-Output ""
        Write-Output "alternative cmake commands:"
        foreach ($l in $alts) {
            Write-Output $l
            Write-Output ""
        }
    }
}

function Test-CMakeLists {
    param(
        [ValidateSet("current","parent")] [string]$Where = "current",
        [string]$Context = "this project"
    )
    $base = if ($Where -eq "parent") { Split-Path -Parent $cwd } else { $cwd }
    $cmakePath = Join-Path $base "CMakeLists.txt"
    if (Test-Path $cmakePath) { return $true }

    Write-Host "CMakeLists.txt not found at: $cmakePath - $Context" -ForegroundColor DarkYellow
    if ($Where -eq "parent") {
        Write-Host "Maybe try:" -ForegroundColor DarkYellow
        Write-Host "-> mkdir build; cd build" -ForegroundColor DarkYellow
        Write-Host "Then run the command again!" -ForegroundColor DarkYellow
    }
    Write-Host "Switching to PRINT-ONLY mode." -ForegroundColor DarkYellow
    Write-Output ""
    $script:OnlyPrint = $true
    return $false
}

# JSON-driven dispatch

# Detect platform so the shared JSON can be filtered.
$Platform = if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) { 'windows' } else { 'linux' }

# vcpkg path detection (Windows-relevant).
function Get-VcpkgPath {
    $primary = $null
    if ($Env:code_root_dir) {
        $primary = Join-Path $Env:code_root_dir "C++/diablo_devilutionX/vcpkg/scripts/buildsystems/vcpkg.cmake"
    }
    $secondary = "C:/local/bin/vcpkg/scripts/buildsystems/vcpkg.cmake"

    if ($primary -and (Test-Path $primary))  { return $primary }
    if (Test-Path $secondary)                 { return $secondary }
    return $null
}

# Substitute {BuildType}, {VCPKG}, {BASE}, {NPROC} tokens.
function Expand-Tokens([string]$text, [string]$base = "", [string]$vcpkg = "", [int]$nproc = 0) {
    if ($null -eq $text) { return "" }
    $out = $text
    $out = $out.Replace('{BuildType}', $BuildType)
    $out = $out.Replace('{VCPKG}',     $vcpkg)
    $out = $out.Replace('{BASE}',      $base)
    $out = $out.Replace('{NPROC}',     "$nproc")
    return $out
}

# Item-level platform filter (used for extras / alternatives / instructions / pre_main_text items).
function Test-ItemPlatform($item, [string]$plat) {
    if ($null -eq $item) { return $false }
    if ($item -is [string]) { return $true }
    if (-not ($item.PSObject.Properties.Name -contains 'platform')) { return $true }
    if (-not $item.platform) { return $true }
    return ($item.platform -eq $plat)
}

# Project-level match: optional platform AND match.all/.any against lowercased $cwd.
function Test-ProjectMatch($proj, [string]$lcCwd, [string]$plat) {
    if ($proj.PSObject.Properties.Name -contains 'platform' -and $proj.platform) {
        if ($proj.platform -ne $plat) { return $false }
    }
    $m = $proj.match
    if (-not $m) { return $false }

    $hasAll = $false; $hasAny = $false
    if ($m.PSObject.Properties.Name -contains 'all' -and $m.all -and $m.all.Count -gt 0) { $hasAll = $true }
    if ($m.PSObject.Properties.Name -contains 'any' -and $m.any -and $m.any.Count -gt 0) { $hasAny = $true }
    if (-not ($hasAll -or $hasAny)) { return $false }

    if ($hasAll) {
        foreach ($needle in $m.all) {
            if ($lcCwd.IndexOf($needle.ToLower()) -lt 0) { return $false }
        }
    }
    if ($hasAny) {
        $ok = $false
        foreach ($needle in $m.any) {
            if ($lcCwd.IndexOf($needle.ToLower()) -ge 0) { $ok = $true; break }
        }
        if (-not $ok) { return $false }
    }
    return $true
}

function Write-MaybeColored([string]$text, $color) {
    if ($color) { Write-Host $text -ForegroundColor $color } else { Write-Output $text }
}

function Invoke-Project($proj) {
    # cmakelists check
    if ($proj.PSObject.Properties.Name -contains 'cmakelists_check' -and $proj.cmakelists_check) {
        Test-CMakeLists -Where $proj.cmakelists_check -Context $proj.context | Out-Null
    }

    # Compute tokens
    $vcpkg = Get-VcpkgPath
    $nproc = [Environment]::ProcessorCount
    $base = ""
    if ($proj.PSObject.Properties.Name -contains 'base_flags' -and $proj.base_flags) {
        $base = Expand-Tokens -text $proj.base_flags -vcpkg $vcpkg -nproc $nproc
    }

    # pre_main_vcpkg block (filtered by its own platform tag)
    if ($proj.PSObject.Properties.Name -contains 'pre_main_vcpkg' -and $proj.pre_main_vcpkg) {
        $pmv = $proj.pre_main_vcpkg
        $pmvPlat = if ($pmv.PSObject.Properties.Name -contains 'platform' -and $pmv.platform) { $pmv.platform } else { 'any' }
        if ($pmvPlat -eq 'any' -or $pmvPlat -eq $Platform) {
            Write-Output ""
            if ($pmv.header) { Write-MaybeColored $pmv.header $pmv.header_color }
            if ($vcpkg) {
                $cmd = Expand-Tokens -text $pmv.command_template -base $base -vcpkg $vcpkg -nproc $nproc
                Write-MaybeColored $cmd $pmv.command_color
            } else {
                $missing = if ($pmv.missing_text) { $pmv.missing_text } else { "(no vcpkg toolchain found at expected paths)" }
                Write-MaybeColored $missing $pmv.command_color
            }
            Write-Output ""
        }
    }

    # pre_main_text array (simple platform-tagged colored notes)
    if ($proj.PSObject.Properties.Name -contains 'pre_main_text' -and $proj.pre_main_text) {
        foreach ($item in $proj.pre_main_text) {
            if (-not (Test-ItemPlatform $item $Platform)) { continue }
            Write-Output ""
            $t = Expand-Tokens -text $item.text -base $base -vcpkg $vcpkg -nproc $nproc
            Write-MaybeColored $t $item.color
            Write-Output ""
        }
    }

    # instructions short-circuit main (used by neovim)
    if ($proj.PSObject.Properties.Name -contains 'instructions' -and $proj.instructions) {
        foreach ($item in $proj.instructions) {
            if ($item -is [string]) {
                Write-Output (Expand-Tokens -text $item -base $base -vcpkg $vcpkg -nproc $nproc)
            } else {
                if (-not (Test-ItemPlatform $item $Platform)) { continue }
                # PS1 implements no `if` predicates; items with `if` are skipped here.
                if ($item.PSObject.Properties.Name -contains 'if' -and $item.if) { continue }
                Write-Output (Expand-Tokens -text $item.text -base $base -vcpkg $vcpkg -nproc $nproc)
            }
        }
        return
    }

    # main (with platform override)
    $mainCmd = ""
    $mainKey = "main_$Platform"
    if ($proj.PSObject.Properties.Name -contains $mainKey -and $proj.$mainKey) {
        $mainCmd = $proj.$mainKey
    }
    elseif ($proj.PSObject.Properties.Name -contains 'main' -and $proj.main) {
        $mainCmd = $proj.main
    }
    if ($mainCmd) {
        Run-Or-Print (Expand-Tokens -text $mainCmd -base $base -vcpkg $vcpkg -nproc $nproc)
    }

    # alternatives (items may be strings OR {platform, command} objects)
    if ($proj.PSObject.Properties.Name -contains 'alternatives' -and $proj.alternatives) {
        $altsArr = @()
        foreach ($item in $proj.alternatives) {
            if ($item -is [string]) {
                $altsArr += Expand-Tokens -text $item -base $base -vcpkg $vcpkg -nproc $nproc
            } else {
                if (-not (Test-ItemPlatform $item $Platform)) { continue }
                $altsArr += Expand-Tokens -text $item.command -base $base -vcpkg $vcpkg -nproc $nproc
            }
        }
        if ($altsArr.Count -gt 0) { Print-Alternatives $altsArr }
    }

    # extras (OnlyPrint mode only)
    if ($OnlyPrint -and $proj.PSObject.Properties.Name -contains 'extras' -and $proj.extras) {
        foreach ($item in $proj.extras) {
            if (-not (Test-ItemPlatform $item $Platform)) { continue }
            switch ($item.type) {
                'blank' { Write-Output "" }
                'text'  { Write-Output (Expand-Tokens -text $item.text -base $base -vcpkg $vcpkg -nproc $nproc) }
                'label_then_command' {
                    if ($item.label) { Write-Output $item.label }
                    Write-Output (Expand-Tokens -text $item.command -base $base -vcpkg $vcpkg -nproc $nproc)
                }
                'label_then_vcpkg_command' {
                    if ($item.label) { Write-Output $item.label }
                    if ($vcpkg) {
                        Write-Output (Expand-Tokens -text $item.command -base $base -vcpkg $vcpkg -nproc $nproc)
                    } else {
                        Write-Output "(no vcpkg toolchain found at expected paths)"
                        if ($item.fallback_command) {
                            Write-Output (Expand-Tokens -text $item.fallback_command -base $base -vcpkg $vcpkg -nproc $nproc)
                        }
                    }
                }
            }
        }
    }

    # variants_print_only (used by my_web_wow c++)
    if ($OnlyPrint -and $base -and $proj.PSObject.Properties.Name -contains 'variants_print_only' -and $proj.variants_print_only) {
        $vp = $proj.variants_print_only
        $prefix = Expand-Tokens -text $vp.prefix -base $base -vcpkg $vcpkg -nproc $nproc
        foreach ($v in $vp.items) {
            $vbase = $base
            foreach ($pair in $v.replace) {
                $vbase = $vbase.Replace($pair[0], $pair[1])
            }
            Write-Output ""
            Write-Output ("{0}:" -f $v.label)
            Write-Output ("{0}{1}" -f $prefix, $vbase)
        }
    }
}

# Default fallback when no project matched or the JSON isn't usable.
function Invoke-DefaultFallback {
    Test-CMakeLists -Where parent -Context (Split-Path -Leaf $cwd) | Out-Null
    Write-Host "No cmake command found for: $cwd" -ForegroundColor DarkYellow
    Write-Host "Using default cmake command..."   -ForegroundColor DarkYellow
    Run-Or-Print "cmake ../ -DCMAKE_BUILD_TYPE=$BuildType"
}

# Load JSON and dispatch
$jsonPath = $null
if ($Env:my_notes_path) {
    $jsonPath = Join-Path $Env:my_notes_path "scripts/cmake-projects.json"
}

if (-not $jsonPath -or -not (Test-Path $jsonPath)) {
    $jsonPathDisplay = $jsonPath
    if (-not $jsonPathDisplay) {
        $jsonPathDisplay = '<$Env:my_notes_path unset>'
    }

    Write-Host "Warning: cmake-projects.json not found at: $jsonPathDisplay" -ForegroundColor Yellow
    Invoke-DefaultFallback
    exit 0
}

try {
    $config = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json
} catch {
    Write-Host "Warning: failed to parse $jsonPath`: $_" -ForegroundColor Yellow
    Invoke-DefaultFallback
    exit 0
}

$matched = $null
foreach ($proj in $config.projects) {
    if (Test-ProjectMatch $proj $lc $Platform) { $matched = $proj; break }
}

if ($matched) {
    Invoke-Project $matched
} else {
    Invoke-DefaultFallback
}
