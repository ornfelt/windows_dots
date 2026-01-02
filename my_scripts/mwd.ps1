$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Wow\tools\my_wow_docs"

if (Test-Path -LiteralPath $basePath -PathType Container) {
    Set-Location -LiteralPath $basePath
    Write-Host ("cd -> {0}" -f $basePath) -ForegroundColor Cyan
} else {
    Write-Host ("[missing] {0}" -f $basePath) -ForegroundColor Red
}

