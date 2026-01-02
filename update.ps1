# Set nvim source dir
$src = ".\nvim"

$destBase = [System.Environment]::ExpandEnvironmentVariables("%localappdata%")
# This also works...
#$dest = [System.Environment]::ExpandEnvironmentVariables("%localappdata%\nvim")

# true to copy full nvim folder into $destBase, otherwise copy all its contents
$copyFullDir = $true
$dest = Join-Path $destBase "nvim"

# Delete destination folder if it exists (to fully replace it)
if ($copyFullDir) {
    # Remove old dir
    if (Test-Path $dest) {
        Remove-Item -Path $dest -Recurse -Force
        Write-Host "Removed existing directory: $dest"
    }
} else {
    # Create destination dir if it doesn't exist
    if (-not (Test-Path $dest)) {
        New-Item -Path $dest -ItemType Directory | Out-Null
    }
}

if ($copyFullDir) {
    # Copy the entire directory as a folder
    Copy-Item -Path $src -Destination $dest -Recurse -Force
} else {
    # Copy only the contents of the directory
    Copy-Item -Path "$src\*" -Destination $dest -Recurse -Force
}

Write-Host "Nvim config files copied successfully from $src to $dest" -ForegroundColor Cyan

# ------------------------------------------------------------
# Copy .vimrc file to h:\ or home dir
if (Test-Path -Path "H:\") {
    $vimrcDest = "H:\.vimrc"
} else {
    $vimrcDest = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\.vimrc")
}

# Copy .vimrc file to the determined destination, forcing overwrite
Copy-Item -Path ".\.vimrc" -Destination $vimrcDest -Force

Write-Host "`n'.vimrc' file copied successfully to $vimrcDest" -ForegroundColor Cyan

# ------------------------------------------------------------
# Copy .wezterm.lua file to home dir
$weztermDest = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\.wezterm.lua")

# Copy .wezterm.lua file
Copy-Item -Path ".\.wezterm.lua" -Destination $weztermDest -Force

Write-Host "`n'.wezterm.lua' file copied successfully to $weztermDest" -ForegroundColor Cyan

# ------------------------------------------------------------
# Check if the .wezterm/wezterm-session-manager directory exists in %USERPROFILE%
$weztermDir = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\.wezterm\wezterm-session-manager")

if (-not (Test-Path -Path $weztermDir)) {
    # Create the directory if it doesn't exist
    New-Item -Path $weztermDir -ItemType Directory -Force

    Write-Host "`nDirectory '$weztermDir' created successfully" -ForegroundColor Green
}

# ------------------------------------------------------------
# Copy files into wezterm-session-manager
$myNotesPath = [System.Environment]::ExpandEnvironmentVariables("%my_notes_path%")

$sessionManagerFile = Join-Path -Path $myNotesPath -ChildPath "scripts\wes\session-manager.lua"
#$weztermStateFile = Join-Path -Path $myNotesPath -ChildPath "scripts\wes\wezterm_state_coding.json"

Copy-Item -Path $sessionManagerFile -Destination $weztermDir -Force
#Copy-Item -Path $weztermStateFile -Destination $weztermDir -Force

Write-Host "`nFiles copied successfully to '$weztermDir'" -ForegroundColor Cyan

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

Write-Host "`n'Copied vs code files (settings.json and keybindings.json) to $destinationDirectory" -ForegroundColor Cyan

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

$settingsItem = Get-Item "C:\users\$env:UserName\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction SilentlyContinue

if (-not $settingsItem) {
    Write-Host "[warn] Could not find Windows Terminal settings.json." -ForegroundColor DarkYellow
} else {
    $settingsPath = $settingsItem.FullName
        try {
            $settingsContent = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
                $fontName = $settingsContent.profiles.defaults.font.face
        } catch {
            Write-Host "[warn] Failed to parse JSON from ${settingsPath}: $_" -ForegroundColor Red
                $fontName = $null
        }

    if ($fontName -eq "JetBrainsMono Nerd Font") {
        Write-Host "Font is set to JetBrainsMono Nerd Font"
            if (Test-Path $alacrittyConfigFile) {
                Replace-FontName -filePath $alacrittyConfigFile -oldFontName $oldFontName -newFontName $newFontName
                    Write-Host "Replaced '$oldFontName' with '$newFontName' in $alacrittyConfigFile" -ForegroundColor DarkBlue
                    $fontReplaced = $true
            } else {
                Write-Host "$alacrittyConfigFile not found." -ForegroundColor DarkYellow
            }
    } elseif ($fontName -eq "JetBrainsMono NF") {
        Write-Host "Font is set to JetBrainsMono NF"
    } else {
        Write-Host "Font wasn't found in profiles.defaults.font.face. Checking file for JetBrainsMono*..." -ForegroundColor DarkYellow
            try {
                $settingsRaw = Get-Content -Path $settingsPath -Raw
                    if ($settingsRaw -match "JetBrainsMono\s*(Nerd Font|NF)") {
                        $match = $matches[0]
                            if ($match -match "Nerd Font") {
                                Write-Host "Font is set to JetBrainsMono Nerd Font (second check)"
                                    if (Test-Path $alacrittyConfigFile) {
                                        Replace-FontName -filePath $alacrittyConfigFile -oldFontName $oldFontName -newFontName $newFontName
                                            Write-Host "Replaced '$oldFontName' with '$newFontName' in $alacrittyConfigFile" -ForegroundColor DarkBlue
                                            $fontReplaced = $true
                                    } else {
                                        Write-Host "$alacrittyConfigFile not found." -ForegroundColor DarkYellow
                                    }
                            } elseif ($match -match "NF") {
                                Write-Host "Font is set to JetBrainsMono NF (second check)"
                            }
                    } else {
                        Write-Host "No JetBrainsMono font found in the settings." -ForegroundColor DarkYellow
                    }
            } catch {
                Write-Host "[warn] Could not read settings file as raw text: $_" -ForegroundColor Red
            }
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

Write-Host "`nFiles copied successfully from $srcAlacritty to $destAlacritty" -ForegroundColor Cyan

# If font was replaced, replace it back
if ($fontReplaced) {
    Replace-FontName -filePath $alacrittyConfigFile -oldFontName $newFontName -newFontName $oldFontName
    Write-Host "Replaced '$newFontName' back to '$oldFontName' in $alacrittyConfigFile" -ForegroundColor DarkBlue
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
        Write-Host "`ncaps_v2.ahk has been copied to the startup folder." -ForegroundColor Cyan
    } else {
        # Copy caps.ahk to the startup folder
        Copy-Item -Path "caps.ahk" -Destination $startupPath -Force
        Write-Host "`ncaps.ahk has been copied to the startup folder." -ForegroundColor Cyan
    }
} else {
    Write-Host "`nAutoHotkey is not installed." -ForegroundColor DarkYellow
}

# ------------------------------------------------------------
# Copy lf config files

# Ensure lf config dir exists
$lfPath = Join-Path $env:localappdata "lf"
if (-not (Test-Path -Path $lfPath)) {
    Write-Host "`nCreating directory: $lfPath" -ForegroundColor Blue
    New-Item -ItemType Directory -Path $lfPath -Force
}

$sourceLfPath = Join-Path $currentDir "lf"
if (Test-Path -Path $sourceLfPath) {
    Write-Host "`nCopying files from $sourceLfPath to $lfPath" -ForegroundColor Cyan
    Copy-Item -Path "$sourceLfPath\*" -Destination $lfPath -Recurse -Force
} else {
    Write-Host "`nSource directory $sourceLfPath does not exist. Skipping copy for lf." -ForegroundColor DarkYellow
}

# ------------------------------------------------------------
# Copy yazi config files

# Ensure yazi config dir exists
$yaziConfigPath = Join-Path $env:appdata "yazi/config"
if (-not (Test-Path -Path $yaziConfigPath)) {
    Write-Host "`nCreating directory: $yaziConfigPath" -ForegroundColor Blue
    New-Item -ItemType Directory -Path $yaziConfigPath -Force
}

$sourceYaziPath = Join-Path $currentDir "yazi"
if (Test-Path -Path $sourceYaziPath) {
    Write-Host "`nCopying files from $sourceYaziPath to $yaziConfigPath" -ForegroundColor Cyan
    Copy-Item -Path "$sourceYaziPath\*" -Destination $yaziConfigPath -Recurse -Force
} else {
    Write-Host "`nSource directory $sourceYaziPath does not exist. Skipping copy for yazi." -ForegroundColor DarkYellow
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
        Write-Host "`nCopying $sourceScriptPath to $yaziConfigPath" -ForegroundColor Cyan
        Copy-Item -Path $sourceScriptPath -Destination $yaziConfigPath -Force
    } else {
        Write-Host "`nScript file $sourceScriptPath does not exist. Skipping." -ForegroundColor DarkYellow
    }
}

