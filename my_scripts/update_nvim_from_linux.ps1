$codeRootDir = $env:code_root_dir

# Define source and target dirs
$dotfilesDir = Join-Path -Path $codeRootDir -ChildPath "Code2/General/dotfiles/.config"
$nvimSourceDir = Join-Path -Path $dotfilesDir -ChildPath "nvim"
$localAppDataDir = [System.Environment]::GetFolderPath('LocalApplicationData')
$nvimTargetDir = Join-Path -Path $localAppDataDir -ChildPath "nvim"

# Check if Git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Output "Git is not installed. Please install Git and try again."
    exit 1
}

# Clone the repository if dotfilesDir doesn't exist
if (-Not (Test-Path -Path $dotfilesDir)) {
    Write-Output "dotfiles directory does not exist. Cloning repository..."
    $repoUrl = "https://github.com/archornf/dotfiles"
    $cloneTargetDir = Join-Path -Path $codeRootDir -ChildPath "Code2/General"
    git clone $repoUrl $cloneTargetDir
}

# Perform a git pull in the repo
Write-Output "Updating dotfiles repository..."
Push-Location -Path $dotfilesDir
git pull
Pop-Location

if (Test-Path -Path $dotfilesDir) {
    # Create the target nvim directory if it doesn't exist
    if (-Not (Test-Path -Path $nvimTargetDir)) {
        New-Item -ItemType Directory -Path $nvimTargetDir | Out-Null
    }

    # Force copy the contents of the nvim directory to %localappdata%\nvim
    Get-ChildItem -Path $nvimSourceDir -Recurse | ForEach-Object {
        $targetPath = $_.FullName -replace [regex]::Escape($nvimSourceDir), $nvimTargetDir
        if ($_.PSIsContainer) {
            if (-Not (Test-Path -Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath | Out-Null
            }
        } else {
            Copy-Item -Path $_.FullName -Destination $targetPath -Force
        }
    }
    Write-Output "nvim directory has been copied to $nvimTargetDir."
} else {
    Write-Output "dotfiles directory does not exist."
}
