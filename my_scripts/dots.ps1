$codeRootDir = $env:code_root_dir

$dotfilesDir = Join-Path -Path $codeRootDir -ChildPath "Code2/General/dotfiles"

# Check if directory exists
if (-Not (Test-Path -Path $dotfilesDir)) {
    Write-Output "Error: dotfiles directory does not exist: $dotfilesDir"
    exit 1
}

Set-Location -Path $dotfilesDir
Write-Host "Dir changed -> $dotfilesDir" -ForegroundColor Cyan
