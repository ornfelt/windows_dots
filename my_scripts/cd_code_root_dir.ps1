$codeRootDir = $env:code_root_dir
$path1 = Join-Path $codeRootDir "Code2"
$path2 = Join-Path $HOME "Code2"
$path3 = "C:/Code2"

function IsValidPath($path) {
    return (Test-Path $path -PathType Container)
}

if ($args.Count -gt 0) {
    if (IsValidPath "$path1") {
        lf -remote "send cd '$(($path1 -replace '\\', '/'))'"
    } elseif (IsValidPath "$path2") {
        lf -remote "send cd '$(($path2 -replace '\\', '/'))'"
    } elseif (IsValidPath "$path3") {
        lf -remote "send cd '$(($path3 -replace '\\', '/'))'"
    } else {
        Write-Host "No valid path found for Code2."
    }
} else {
    if (IsValidPath "$path1") {
        ya emit-to 0 cd "$path1"
    } elseif (IsValidPath "$path2") {
        ya emit-to 0 cd "$path2"
    } elseif (IsValidPath "$path3") {
        ya emit-to 0 cd "$path3"
    } else {
        Write-Host "No valid path found for Code2."
    }
}

