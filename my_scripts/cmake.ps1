param(
    [Parameter(Position=0)]
    [string]$Arg,

    [Parameter(Position=1)]
    [string]$Arg2
)

# Usage:
# .\cmake.ps1            # detect path and RUN the chosen cmake
# .\cmake.ps1 onlyprint  # detect path and PRINT commands (no execution)
# .\cmake.ps1 r/release  # RUN in Release mode
# .\cmake.ps1 r foo      # RUN in Release mode and PRINT commands (no execution)

# Print-only unless argument is "r" or "release" (case-insensitive)
$OnlyPrint = $null
$Release = $false

if (-not [string]::IsNullOrWhiteSpace($Arg)) {
    $arg_lc = $Arg.ToLowerInvariant()

    if ($arg_lc -eq 'r' -or $arg_lc -eq 'release') {
        $Release = $true
        # If there's also another arg, enable print-only too
        if (-not [string]::IsNullOrWhiteSpace($Arg2)) {
            $OnlyPrint = 'true'
        }
    }
    else {
        $OnlyPrint = 'true'
    }

    Write-Host "If needed, run:" -ForegroundColor Blue
    Write-Host 'make -j$([Environment]::ProcessorCount)' -ForegroundColor Blue
}

# build type helper
$BuildType = 'Debug'
if ($Release) { $BuildType = 'Release' }

# Debug print
if ($OnlyPrint) {
    Write-Host ("[OnlyPrint]=ON  [BuildType]={0}" -f $BuildType) -ForegroundColor Magenta
}
else {
    Write-Host ("[OnlyPrint]=OFF  [BuildType]={0}" -f $BuildType) -ForegroundColor Magenta
}

# Note: most of the cmake commands are only tested on linux

$cwd = (Get-Location).Path

function Run-Or-Print {
    param([string]$Cmd)
    if ($OnlyPrint) {
        Write-Output $Cmd
    } else {
        Write-Host "Executing: $Cmd" -ForegroundColor Cyan
        Invoke-Expression $Cmd
    }
}

# Helper: print a block of alternatives nicely
function Print-Alternatives {
    param([string[]]$Lines)
    if ($OnlyPrint -and $Lines.Count -gt 0) {
        Write-Output ""
        Write-Output "alternative cmake commands:"
        foreach ($l in $Lines) {
            Write-Output $l
            Write-Output ""
        }
    }
}

function Test-CMakeLists {
    param(
        [switch]$ParentDir, # if set: check parent; else: current dir
        [string]$Context = '' # optional label for nicer messages
    )

    $base = (Get-Location).Path
    if ($ParentDir) { $base = Split-Path -Path $base -Parent }

    $cmakePath = Join-Path $base 'CMakeLists.txt'

    if (Test-Path -LiteralPath $cmakePath) {
        return $cmakePath
    }

    # Not found: inform + force print-only
    if ([string]::IsNullOrWhiteSpace($Context)) { $Context = 'this project' }

    Write-Host "CMakeLists.txt not found at: $cmakePath ($Context)" -ForegroundColor Yellow
    if ($ParentDir) { 
        Write-Host "Maybe try:`n-> mkdir build; cd build`nThen try again!" -ForegroundColor Yellow
    }
    Write-Host "Switching to PRINT-ONLY mode." -ForegroundColor Yellow
    Write-Host ""
    $script:OnlyPrint = 'true'

    return $null
}

# Make string checks case-insensitive (can use -imatch to be more explicit)
$azMatch = $cwd -match 'azerothcore'
$tcMatch = $cwd -match 'trinitycore'
$wowCppMatch = ($cwd -match 'my_web_wow') -and ($cwd -match 'c\+\+')

if ($azMatch) {
    $null = Test-CMakeLists -ParentDir -Context 'azerothcore (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
    $alts = @(
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug',
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
    )

    Run-Or-Print $main
    Print-Alternatives $alts
}
elseif ($tcMatch) {
    $null = Test-CMakeLists -ParentDir -Context 'trinitycore (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
    $alts = @(
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug',
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/tcore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
    )

    Run-Or-Print $main
    Print-Alternatives $alts
}
elseif ($wowCppMatch) {
    $null = Test-CMakeLists -Context 'my_web_wow c++ (expecting CMakeLists.txt in current directory)'
    # Windows / vcpkg toolchain case
    $vcpkgPrimary   = 'C:/Users/jonas/Code2/C++/diablo_devilutionX/vcpkg/scripts/buildsystems/vcpkg.cmake'
    $vcpkgSecondary = 'C:/local/bin/vcpkg/scripts/buildsystems/vcpkg.cmake'

    if (Test-Path $vcpkgPrimary) {
        $main = "cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=`"$vcpkgPrimary`" -DUSE_VCPKG=ON -DCMAKE_BUILD_TYPE=$BuildType"
    }
    elseif (Test-Path $vcpkgSecondary) {
        $main = "cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=`"$vcpkgSecondary`" -DUSE_VCPKG=ON -DCMAKE_BUILD_TYPE=$BuildType"
    }
    else {
        $main = "cmake -B build -S . -DCMAKE_BUILD_TYPE=$BuildType"
    }

    Run-Or-Print $main

    if ($OnlyPrint) {
        Write-Output ""
        Write-Output "alternative cmake command without vcpkg:"
        Write-Output 'cmake -B build -S . -DCMAKE_BUILD_TYPE=Release'
    }
}
elseif ($cwd -imatch 'openjk') {
    $null = Test-CMakeLists -ParentDir -Context 'openjk (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local/share/openjk -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'jediknightgalaxies') {
    $null = Test-CMakeLists -ParentDir -Context 'jediknightgalaxies (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake -DCMAKE_INSTALL_PREFIX=$HOME/Downloads/ja_data -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'stk-code') {
    $null = Test-CMakeLists -ParentDir -Context 'stk-code (expecting CMakeLists.txt one level up)'
    $main = 'cmake .. -DCMAKE_BUILD_TYPE=Release -DNO_SHADERC=on'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'dhewm3') {
    $main = 'cmake ../neo/'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'blpconverter') {
    $null = Test-CMakeLists -ParentDir -Context 'blpconverter (expecting CMakeLists.txt one level up)'
    $main = 'cmake .. -DWITH_LIBRARY=YES'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'stormlib') {
    $null = Test-CMakeLists -ParentDir -Context 'stormlib (expecting CMakeLists.txt one level up)'
    $main = 'cmake .. -DBUILD_SHARED_LIBS=ON'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'mangos-classic') {
    $null = Test-CMakeLists -ParentDir -Context 'mangos-classic (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake .. -DCMAKE_INSTALL_PREFIX=~/cmangos/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'mangos-tbc') {
    $null = Test-CMakeLists -ParentDir -Context 'mangos-tbc (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake -S .. -B ./ -DCMAKE_INSTALL_PREFIX=~/cmangos-tbc/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON -DCMAKE_BUILD_TYPE=Release'
    $alts = @(
        'cmake -S .. -B ./ -DCMAKE_INSTALL_PREFIX=~/cmangos-tbc/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=1 -DBUILD_PLAYERBOTS=ON -DCMAKE_BUILD_TYPE=Debug'
    )

    Run-Or-Print $main
    Print-Alternatives $alts

    if ($OnlyPrint) {
        Write-Output ""
        Write-Output "alternative cmake command with clang:"
        Write-Output 'cmake .. -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ ...'
    }
}
elseif ($cwd -imatch 'core') {
    $null = Test-CMakeLists -ParentDir -Context 'vmangos(core) (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake .. -DDEBUG=0 -DSUPPORTED_CLIENT_BUILD=5875 -DUSE_EXTRACTORS=1 -DCMAKE_INSTALL_PREFIX=$HOME/vmangos'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'server') {
    $null = Test-CMakeLists -ParentDir -Context 'mangoszero(server) (expecting CMakeLists.txt one level up)'
    # linux-specific...
    $main = 'cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=0 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run'

    Run-Or-Print $main
    if ($OnlyPrint) {
        Write-Output ""
        Write-Output "alternative cmake command with eluna:"
        Write-Output 'cmake -S .. -B ./ -DBUILD_MANGOSD=1 -DBUILD_REALMD=1 -DBUILD_TOOLS=1 -DUSE_STORMLIB=1 -DSCRIPT_LIB_ELUNA=1 -DSCRIPT_LIB_SD3=1 -DPLAYERBOTS=1 -DPCH=1 -DCMAKE_INSTALL_PREFIX=$HOME/mangoszero/run'
    }
}
elseif (($cwd -match 'tbc') -and ($cwd -match 'c\+\+')) {
    $null = Test-CMakeLists -ParentDir -Context 'my_wow tbc c++ (expecting CMakeLists.txt one level up)'
    $main = "cmake .. -DUSE_SDL2=ON -DUSE_SOUND=ON -DUSE_NAMIGATOR=OFF -DUSE_STOPWATCH_DT=ON -DCMAKE_BUILD_TYPE=$BuildType"
    $alts = @(
        "cmake .. -DUSE_SDL2=OFF -DUSE_SOUND=ON -DUSE_NAMIGATOR=ON -DUSE_STOPWATCH_DT=OFF -DCMAKE_BUILD_TYPE=$BuildType"
    )

    Run-Or-Print $main
    Print-Alternatives $alts
}
elseif ($cwd -imatch 'neovim') {
    $null = Test-CMakeLists -Context 'neovim (expecting CMakeLists.txt in current directory)'

    Write-Output "Do the following:"
    Write-Output "git checkout stable"
    Write-Output "make CMAKE_BUILD_TYPE={Release / RelWithDebInfo}"
    Write-Output "sudo make install"
}
elseif ($cwd -imatch 'ioq3') {
    $null = Test-CMakeLists -Context 'ioq3 (expecting CMakeLists.txt in current directory)'

    $main = "cmake -S . -B build -G `"Visual Studio 17 2022`"; cmake --build build --config $BuildType"
    $alts = @(
        "cmake -S . -B build -G `"Visual Studio 17 2022`"; cmake --build build --config $BuildType"
    )

    Run-Or-Print $main
    Print-Alternatives $alts
}
elseif ($cwd -imatch 'torchless') {
    $null = Test-CMakeLists -ParentDir -Context 'torchless (expecting CMakeLists.txt one level up)'
    $main = 'cmake .. -DCMAKE_BUILD_TYPE=Release'

    Run-Or-Print $main
    if ($OnlyPrint) {
        Write-Output ""
        Write-Output "compile command:"
        Write-Output "cmake .. -DCMAKE_BUILD_TYPE=Release; cmake --build ."
        Write-Output "On windows, run cmake, then build in vs:"
        Write-Output ".\*.slnx"
    }
}
elseif ($cwd -imatch 'ollama') {
    # linux-specific...
    $null = Test-CMakeLists -Context 'ollama (expecting CMakeLists.txt in current directory)'

    $main = "cmake -B build; cmake --build build -j $([Environment]::ProcessorCount)"
    Run-Or-Print $main
}
elseif ($cwd -imatch 'llama\.cpp') {
    # linux-specific...
    $null = Test-CMakeLists -Context 'llama.cpp (expecting CMakeLists.txt in current directory)'

    $main = "cmake -B build; cmake --build build --config Release -j $([Environment]::ProcessorCount)"
    Run-Or-Print $main

    if ($OnlyPrint) {
        Write-Output ""
        Write-Output "cmake -B build; cmake --build build --config $BuildType -j $([Environment]::ProcessorCount)"
    }
}
else {
    # Default fallback
    #$null = Test-CMakeLists -ParentDir
    $null = Test-CMakeLists -ParentDir -Context (Split-Path -Leaf (Get-Location))

    Write-Host "No cmake command found for: $cwd" -ForegroundColor DarkYellow
    Write-Host "Using default cmake command..." -ForegroundColor DarkYellow
    $main = "cmake ../ -DCMAKE_BUILD_TYPE=$BuildType"
    Run-Or-Print $main
}

