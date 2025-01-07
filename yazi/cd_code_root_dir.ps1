$codeRootDir = $env:code_root_dir
$path1 = Join-Path $codeRootDir "Code2"
$path2 = Join-Path $HOME "Code2"
$path3 = "C:\Code2"

function IsValidPath($path) {
    return (Test-Path $path -PathType Container)
}

if (IsValidPath $path1) {
    ya emit-to 0 cd $path1
} elseif (IsValidPath $path2) {
    ya emit-to 0 cd $path2
} elseif (IsValidPath $path3) {
    ya emit-to 0 cd $path3
} else {
    Write-Host "No valid path found for Code2."
}

