$codeRootDir = $env:code_root_dir

# -- Color helpers -------------------------------------------------------------

function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err     ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }

# Prompt for confirmation before proceeding
Write-Host "Do you want to proceed? " -ForegroundColor DarkYellow -NoNewline
$confirmation = Read-Host "(y/n)"
if ($confirmation -notmatch "^(?i)y(?:es)?$") {
    Write-Warn "Operation canceled by the user."
    exit 0
}

# Define source and target dirs
$dotfilesDir = Join-Path -Path $codeRootDir -ChildPath "Code2/General/dotfiles/.config"
$nvimSourceDir = Join-Path -Path $dotfilesDir -ChildPath "nvim"
$localAppDataDir = [System.Environment]::GetFolderPath('LocalApplicationData')
$nvimTargetDir = Join-Path -Path $localAppDataDir -ChildPath "nvim"

# Check if Git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git is not installed. Please install Git and try again."
    exit 1
}

# Clone the repository if dotfilesDir doesn't exist
if (-Not (Test-Path -Path $dotfilesDir)) {
    Write-Info "dotfiles directory does not exist. Cloning repository..."
    $repoUrl = "https://github.com/archornf/dotfiles"
    $cloneTargetDir = Join-Path -Path $codeRootDir -ChildPath "Code2/General/dotfiles"
    git clone $repoUrl $cloneTargetDir
}

# Perform a git pull in the repo
Write-Info "Updating dotfiles repository..."
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
    Write-Ok "nvim directory has been copied to $nvimTargetDir."
} else {
    Write-Err "dotfiles directory does not exist."
}

$weztermSourceFile = Join-Path -Path (Split-Path -Path $dotfilesDir -Parent) -ChildPath ".wezterm.lua"
$userProfileDir = [System.Environment]::GetFolderPath('UserProfile')
$weztermTargetFile = Join-Path -Path $userProfileDir -ChildPath ".wezterm.lua"

if (Test-Path -Path $weztermSourceFile) {
    Copy-Item -Path $weztermSourceFile -Destination $weztermTargetFile -Force
    Write-Ok ".wezterm.lua has been copied to $weztermTargetFile."
} else {
    Write-Warn ".wezterm.lua file not found in $dotfilesDir."
}

# Sync wezterm lua modules into ~/.wezterm: every .lua file directly in
# .config/wezterm (not recursive, so wezterm-session-manager/ is left alone)
$weztermModulesSourceDir = Join-Path -Path $dotfilesDir -ChildPath "wezterm"
$weztermModulesTargetDir = Join-Path -Path $userProfileDir -ChildPath ".wezterm"

if (-Not (Test-Path -Path $weztermModulesTargetDir)) {
    New-Item -ItemType Directory -Path $weztermModulesTargetDir | Out-Null
}

$weztermModuleFiles = @(Get-ChildItem -Path $weztermModulesSourceDir -Filter "*.lua" -File -ErrorAction SilentlyContinue)
if ($weztermModuleFiles.Count -eq 0) {
    Write-Warn "No wezterm .lua files found in $weztermModulesSourceDir."
}

foreach ($moduleFile in $weztermModuleFiles) {
    Copy-Item -Path $moduleFile.FullName -Destination $weztermModulesTargetDir -Force
    Write-Ok "$($moduleFile.Name) has been copied to $weztermModulesTargetDir."
}

