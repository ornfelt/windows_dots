$currentDir = Get-Location

$codeRootDir = $env:code_root_dir
if (-not $codeRootDir) {
    Write-Error "Environment variable 'code_root_dir' is not set."
    exit 1
}

$cavaDir = Join-Path -Path $codeRootDir -ChildPath "Code\c\cava\cava_win\x64\Release"

$cavaExe = Join-Path -Path $cavaDir -ChildPath "cava.exe"
if (Test-Path $cavaExe) {
    Set-Location -Path $cavaDir

    Write-Host "Running cava.exe from $cavaDir"
    .\cava.exe

    Set-Location -Path $currentDir
    Write-Host "Returned to initial directory: $currentDir"
} else {
    Write-Warning "cava.exe not found in $cavaDir."
}

