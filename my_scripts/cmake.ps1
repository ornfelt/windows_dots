param(
    [Parameter(Position=0)]
    [string]$OnlyPrint
)

# TODO: go through all cmake commands from setup.sh!

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

# Make string checks case-insensitive
$azMatch = $cwd -match 'azerothcore'
$tcMatch = $cwd -match 'trinitycore'
$wowCppMatch = ($cwd -match 'my_web_wow') -and ($cwd -match 'c\+\+')

if ($azMatch) {
    $main = 'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo'
    $alts = @(
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=1 -DCMAKE_BUILD_TYPE=Debug',
        'cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/acore/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static -DWITH_COREDEBUG=0 -DCMAKE_BUILD_TYPE=Release'
    )

    Run-Or-Print $main
    Print-Alternatives $alts
}
elseif ($tcMatch) {
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
        Write-Output 'cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug'
    }
}
else {
    # Default fallback
    $main = 'cmake ../ -DCMAKE_BUILD_TYPE=Release'
    Run-Or-Print $main
}

