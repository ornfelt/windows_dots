param (
    [string]$buildConfig = "debug",
    [bool]  $useCmake = $true
)

# Example:
# .\wc.ps1 -buildConfig debug   -useCmake:$false
# .\wc.ps1 -buildConfig release -useCmake:$true

if ($buildConfig -ieq "d" -or $buildConfig -ieq "debug") {
    $buildFolder = "Debug_x64"
} else {
    $buildFolder = "Release_x64"
}

# original version
#$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Wow\tools\my_wow\c\wc\bin\$buildFolder"
# clean version (only used if useCmake is false)
$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Wow\tools\my_wow\c\wc_clean\bin\$buildFolder"

# Adapt for cmake version...
if ($useCmake) {
    if ($buildConfig -ieq "d" -or $buildConfig -ieq "debug") {
        $buildFolder = "build\bin\Debug"
    } else {
        $buildFolder = "build\bin\Release"
    }

    # cmake version
    $basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Wow\tools\my_wow\c\wc_clean\$buildFolder"
}

if (Test-Path $basePath) {
    $path = $basePath
} else {
    Write-Host "Couldn't find wc bin path. Is it compiled?"
    exit 1
}

cd $path

echo "Usage examples:"
echo "./client.exe -h"
echo "./client.exe -s GlueXML"
echo "./client.exe -s FrameXML"
echo "./client.exe -p $env:wow_tbc_dir -m 0"

