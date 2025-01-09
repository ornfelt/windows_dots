# Set the source directory
$src = ".\nvim"
# Set the destination directory, expanding the environment variable
$dest = [System.Environment]::ExpandEnvironmentVariables("%localappdata%\nvim")

# Create the destination directory if it doesn't exist
if (-not (Test-Path $dest)) {
    New-Item -Path $dest -ItemType Directory
}

# Copy all contents from source to destination, forcing overwrite
Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force

Write-Host "Files copied successfully from $src to $dest"

# ------------------------------------------------------------
# Copy .vimrc file to h:\ or home dir
if (Test-Path -Path "H:\") {
    $vimrcDest = "H:\.vimrc"
} else {
    $vimrcDest = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\.vimrc")
}

# Copy .vimrc file to the determined destination, forcing overwrite
Copy-Item -Path ".\.vimrc" -Destination $vimrcDest -Force

Write-Host "`n'.vimrc' file copied successfully to $vimrcDest"

# ------------------------------------------------------------
# Copy .wezterm.lua file to home dir
$weztermDest = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\.wezterm.lua")

# Copy .wezterm.lua file
Copy-Item -Path ".\.wezterm.lua" -Destination $weztermDest -Force

Write-Host "`n'.wezterm.lua' file copied successfully to $weztermDest"

# ------------------------------------------------------------
# Check if the .wezterm/wezterm-session-manager directory exists in %USERPROFILE%
$weztermDir = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\.wezterm\wezterm-session-manager")

if (-not (Test-Path -Path $weztermDir)) {
    # Create the directory if it doesn't exist
    New-Item -Path $weztermDir -ItemType Directory -Force

    Write-Host "`nDirectory '$weztermDir' created successfully"
}

# ------------------------------------------------------------
# Copy files into wezterm-session-manager
$myNotesPath = [System.Environment]::ExpandEnvironmentVariables("%my_notes_path%")

$sessionManagerFile = Join-Path -Path $myNotesPath -ChildPath "scripts\wes\session-manager.lua"
#$weztermStateFile = Join-Path -Path $myNotesPath -ChildPath "scripts\wes\wezterm_state_coding.json"

Copy-Item -Path $sessionManagerFile -Destination $weztermDir -Force
#Copy-Item -Path $weztermStateFile -Destination $weztermDir -Force

Write-Host "`nFiles copied successfully to '$weztermDir'"

# ------------------------------------------------------------
# Copy vscode files

$currentDir = Get-Location
$keybindingsFile = Join-Path -Path $currentDir -ChildPath "Code\keybindings.json"
$settingsFile = Join-Path -Path $currentDir -ChildPath "Code\settings.json"

$destinationDirectory = [System.IO.Path]::Combine($env:APPDATA, "Code\User")

if (-not (Test-Path -Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force
}

Copy-Item -Path $keybindingsFile -Destination $destinationDirectory -Force
Copy-Item -Path $settingsFile -Destination $destinationDirectory -Force

Write-Host "`n'Copied vs code files (settings.json and keybindings.json) to $destinationDirectory"

# ------------------------------------------------------------
# Replace font name in alacritty.toml and copy alacritty to %appdata
function Replace-FontName {
    param (
        [string]$filePath,
        [string]$oldFontName,
        [string]$newFontName
    )
    $content = Get-Content -Path $filePath
    $updatedContent = $content -replace $oldFontName, $newFontName
    Set-Content -Path $filePath -Value $updatedContent
}

$fontReplaced = $false
$alacrittyConfigFile = ".\alacritty\alacritty.toml"
$oldFontName = "JetBrainsMono NF"
$newFontName = "JetBrainsMono Nerd Font" # With spaces

$settingsPath = (Get-Item "C:\users\$env:UserName\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json").FullName
$settingsContent = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
$fontName = $settingsContent.profiles.defaults.font.face

if ($fontName -eq "JetBrainsMono Nerd Font") {
    Write-Output "Font is set to JetBrainsMono Nerd Font"
    if (Test-Path $alacrittyConfigFile) {
        Replace-FontName -filePath $alacrittyConfigFile -oldFontName $oldFontName -newFontName $newFontName
        Write-Host "Replaced '$oldFontName' with '$newFontName' in $alacrittyConfigFile"
        $fontReplaced = $true
    } else {
        Write-Host "$alacrittyConfigFile not found."
    }
} elseif ($fontName -eq "JetBrainsMono NF") {
    Write-Output "Font is set to JetBrainsMono NF"
} else {
    Write-Output "Font wasn't found in profiles.defaults.font.face. Checking file for JetBrainsMono*..."
    $settingsContent = Get-Content -Path $settingsPath -Raw
    if ($settingsContent -match "JetBrainsMono\s*(Nerd Font|NF)") {
        $match = $matches[0]
            if ($match -match "Nerd Font") {
                Write-Output "Font is set to JetBrainsMono Nerd Font (second check)"
                if (Test-Path $alacrittyConfigFile) {
                        Replace-FontName -filePath $alacrittyConfigFile -oldFontName $oldFontName -newFontName $newFontName
                        Write-Host "Replaced '$oldFontName' with '$newFontName' in $alacrittyConfigFile"
                        $fontReplaced = $true
                    } else {
                        Write-Host "$alacrittyConfigFile not found."
                    }
            } elseif ($match -match "NF") {
                Write-Output "Font is set to JetBrainsMono NF (second check)"
            }
    } else {
        Write-Output "No JetBrainsMono font found in the settings."
    }
}

$srcAlacritty = ".\alacritty"
# Set destination directory for alacritty, expanding the environment variable
$destAlacritty = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\alacritty")

# Create destination dir if it doesn't exist
if (-not (Test-Path $destAlacritty)) {
    New-Item -Path $destAlacritty -ItemType Directory
}

# Copy contents from alacritty source to destination, forcing overwrite
Copy-Item -Path "$srcAlacritty\*" -Destination $destAlacritty -Recurse -Force

Write-Host "`nFiles copied successfully from $srcAlacritty to $destAlacritty"

# If font was replaced, replace it back
if ($fontReplaced) {
    Replace-FontName -filePath $alacrittyConfigFile -oldFontName $newFontName -newFontName $oldFontName
    Write-Host "Replaced '$newFontName' back to '$oldFontName' in $alacrittyConfigFile"
}

# 'oh-my-posh font install' to install JetBrains font...

# ------------------------------------------------------------
# Move AutoHotKey script

$autohotkeyPath = "C:\Program Files\AutoHotkey"
$v2Path = Join-Path $autohotkeyPath "v2"
# shell:startup
$startupPath = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")

# Check if the AutoHotkey directory exists
if (Test-Path $autohotkeyPath) {
    # Check if the v2 directory exists
    if (Test-Path $v2Path) {
        # Copy caps_v2.ahk to the startup folder
        Copy-Item -Path "caps_v2.ahk" -Destination $startupPath -Force
        Write-Output "`ncaps_v2.ahk has been copied to the startup folder."
    } else {
        # Copy caps.ahk to the startup folder
        Copy-Item -Path "caps.ahk" -Destination $startupPath -Force
        Write-Output "`ncaps.ahk has been copied to the startup folder."
    }
} else {
    Write-Output "`nAutoHotkey is not installed."
}

# ------------------------------------------------------------
# Copy lf config files

# Ensure lf config dir exists
$lfPath = Join-Path $env:localappdata "lf"
if (-not (Test-Path -Path $lfPath)) {
    Write-Host "`nCreating directory: $lfPath"
    New-Item -ItemType Directory -Path $lfPath -Force
}

$sourceLfPath = Join-Path $currentDir "lf"
if (Test-Path -Path $sourceLfPath) {
    Write-Host "`nCopying files from $sourceLfPath to $lfPath"
    Copy-Item -Path "$sourceLfPath\*" -Destination $lfPath -Recurse -Force
} else {
    Write-Warning "`nSource directory $sourceLfPath does not exist. Skipping copy for lf."
}

# ------------------------------------------------------------
# Copy yazi config files

# Ensure yazi config dir exists
$yaziConfigPath = Join-Path $env:appdata "yazi/config"
if (-not (Test-Path -Path $yaziConfigPath)) {
    Write-Host "`nCreating directory: $yaziConfigPath"
    New-Item -ItemType Directory -Path $yaziConfigPath -Force
}

$sourceYaziPath = Join-Path $currentDir "yazi"
if (Test-Path -Path $sourceYaziPath) {
    Write-Host "`nCopying files from $sourceYaziPath to $yaziConfigPath"
    Copy-Item -Path "$sourceYaziPath\*" -Destination $yaziConfigPath -Recurse -Force
} else {
    Write-Warning "`nSource directory $sourceYaziPath does not exist. Skipping copy for yazi."
}

$scriptFiles = @(
    "my_scripts/cd_code_root_dir.ps1",
    "my_scripts/cd_my_notes_path.ps1",
    "my_scripts/cd_ps_profile_path.ps1"
    "my_scripts/copy_path.ps1"
)

foreach ($script in $scriptFiles) {
    $sourceScriptPath = Join-Path $currentDir $script
    if (Test-Path -Path $sourceScriptPath) {
        Write-Host "`nCopying $sourceScriptPath to $yaziConfigPath"
        Copy-Item -Path $sourceScriptPath -Destination $yaziConfigPath -Force
    } else {
        Write-Warning "`nScript file $sourceScriptPath does not exist. Skipping."
    }
}

