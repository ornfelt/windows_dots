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

# Copy the .vimrc file to the determined destination, forcing overwrite
Copy-Item -Path ".\.vimrc" -Destination $vimrcDest -Force

Write-Host "`n'.vimrc' file copied successfully to $vimrcDest"

# TODO: also copy vscode settings?

# Windows %APPDATA%\Code\User\settings.json.
# macOS $HOME/Library/Application\ Support/Code/User/settings.json.
# Linux $HOME/.config/Code/User/settings.json.

# ------------------------------------------------------------
# Replace font name in alacritty.toml and copy alacritty to %appdata
function Replace-FontName {
    param (
        [string]$filePath,
        [string]$oldFontName,
        [string]$newFontName
    )

    # Read the content of the file
    $content = Get-Content -Path $filePath

    # Replace the font name
    $updatedContent = $content -replace $oldFontName, $newFontName

    # Write the updated content back to the file
    Set-Content -Path $filePath -Value $updatedContent
}

# Check if fonts directory contains JetBrainsMonoNerdFont* files
$fontsDir = "C:\Windows\Fonts"
$nerdFonts = Get-ChildItem -Path $fontsDir -Filter "JetBrainsMonoNerdFont*"

$fontReplaced = $false
$alacrittyConfigFile = ".\alacritty\alacritty.toml"
$oldFontName = "JetBrainsMono NF"
$newFontName = "JetBrainsMono Nerd Font" # With spaces

if ($nerdFonts.Count -gt 0) {
    if (Test-Path $alacrittyConfigFile) {
        Replace-FontName -filePath $alacrittyConfigFile -oldFontName $oldFontName -newFontName $newFontName
        Write-Host "Replaced '$oldFontName' with '$newFontName' in $alacrittyConfigFile"
        $fontReplaced = $true
    } else {
        Write-Host "$alacrittyConfigFile not found."
    }
} else {
    Write-Host "No JetBrainsMonoNerdFont* files found in $fontsDir"
}

$srcAlacritty = ".\alacritty"
# Set the destination directory for alacritty, expanding the environment variable
$destAlacritty = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\alacritty")

# Create the destination directory if it doesn't exist
if (-not (Test-Path $destAlacritty)) {
    New-Item -Path $destAlacritty -ItemType Directory
}

# Copy all contents from alacritty source to destination, forcing overwrite
Copy-Item -Path "$srcAlacritty\*" -Destination $destAlacritty -Recurse -Force

Write-Host "`nFiles copied successfully from $srcAlacritty to $destAlacritty"

# If the font was replaced, replace it back
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
