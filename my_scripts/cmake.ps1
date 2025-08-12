param(
    [Parameter(Position=0)]
    [string]$OnlyPrint
)

# Usage:
# .\cmake.ps1            # detect path and RUN the chosen cmake
# .\cmake.ps1 onlyprint  # detect path and PRINT commands (no execution)

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
        foreach ($l in $Lines) { Write-Output $l }
    }
}

# Make string checks case-insensitive (can use -imatch to be more explicit)
$azMatch = $cwd -match 'azerothcore'
$tcMatch = $cwd -match 'trinitycore'
$wowCppMatch = ($cwd -match 'my_web_wow') -and ($cwd -match 'c\+\+')

if ($azMatch) {
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
    # Windows / vcpkg toolchain case
    $vcpkgPrimary   = 'C:/Users/jonas/Code2/C++/diablo_devilutionX/vcpkg/scripts/buildsystems/vcpkg.cmake'
    $vcpkgSecondary = 'C:/local/bin/vcpkg/scripts/buildsystems/vcpkg.cmake'

    if (Test-Path $vcpkgPrimary) {
        $main = "cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=`"$vcpkgPrimary`" -DUSE_VCPKG=ON -DCMAKE_BUILD_TYPE=Debug"
    }
    elseif (Test-Path $vcpkgSecondary) {
        $main = "cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=`"$vcpkgSecondary`" -DUSE_VCPKG=ON -DCMAKE_BUILD_TYPE=Debug"
    }
    else {
        $main = 'cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug'
    }

    Run-Or-Print $main

    if ($OnlyPrint) {
        Write-Output ""
        Write-Output "alternative cmake command without vcpkg:"
        Write-Output 'cmake -B build -S . -DCMAKE_BUILD_TYPE=Release'
    }
}
elseif ($cwd -imatch 'openjk') {
    # linux-specific...
    $main = 'cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local/share/openjk -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'jediknightgalaxies') {
    # linux-specific...
    $main = 'cmake -DCMAKE_INSTALL_PREFIX=$HOME/Downloads/ja_data -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'stk-code') {
    $main = 'cmake .. -DCMAKE_BUILD_TYPE=Release -DNO_SHADERC=on'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'dhewm3') {
    $main = 'cmake ../neo/'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'blpconverter') {
    $main = 'cmake .. -DWITH_LIBRARY=YES'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'stormlib') {
    $main = 'cmake .. -DBUILD_SHARED_LIBS=ON'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'mangos-classic') {
    # linux-specific...
    $main = 'cmake .. -DCMAKE_INSTALL_PREFIX=~/cmangos/run -DBUILD_EXTRACTORS=ON -DPCH=1 -DDEBUG=0 -DBUILD_PLAYERBOTS=ON'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'mangos-tbc') {
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
    # linux-specific...
    $main = 'cmake .. -DDEBUG=0 -DSUPPORTED_CLIENT_BUILD=5875 -DUSE_EXTRACTORS=1 -DCMAKE_INSTALL_PREFIX=$HOME/vmangos'
    Run-Or-Print $main
}
elseif ($cwd -imatch 'server') {
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
    $main = 'cmake .. -DUSE_SDL2=ON -DUSE_SOUND=ON -DUSE_NAMIGATOR=ON -DCMAKE_BUILD_TYPE=Debug'
    $alts = @(
        'cmake .. -DUSE_SDL2=OFF -DUSE_SOUND=ON -DUSE_NAMIGATOR=OFF -DCMAKE_BUILD_TYPE=Release'
    )

    Run-Or-Print $main
    Print-Alternatives $alts
}
else {
    # Default fallback
    Write-Host "No cmake command found for: $cwd" -ForegroundColor DarkYellow
    Write-Host "Using default cmake command..." -ForegroundColor DarkYellow
    $main = 'cmake ../ -DCMAKE_BUILD_TYPE=Debug'
    Run-Or-Print $main
}

