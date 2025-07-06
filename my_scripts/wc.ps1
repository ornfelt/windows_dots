param (
    [string]$buildConfig = "debug"
)

if ($buildConfig -ieq "d" -or $buildConfig -ieq "debug") {
    $buildFolder = "Debug_x64"
} else {
    $buildFolder = "Release_x64"
}

#$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Wow\tools\my_wow\c\wc\bin\$buildFolder"
$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Wow\tools\my_wow\c\wc_clean\bin\$buildFolder"

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

