## Replace font name in alacritty.toml and copy alacritty to %appdata
#function Replace-FontName {
#    param (
#        [string]$filePath,
#        [string]$oldFontName,
#        [string]$newFontName
#    )
#
#    # Read the content of the file
#    $content = Get-Content -Path $filePath
#
#    # Replace the font name
#    $updatedContent = $content -replace $oldFontName, $newFontName
#
#    # Write the updated content back to the file
#    Set-Content -Path $filePath -Value $updatedContent
#}
#
## Check if fonts directory contains JetBrainsMonoNerdFont* files
#$fontsDir = "C:\Windows\Fonts"
#$nerdFonts = Get-ChildItem -Path $fontsDir -Filter "JetBrainsMonoNerdFont*"
#$nerdFontsAlt = Get-ChildItem -Path $fontsDir -Filter "JetBrainsMono Nerd*"
#
#$fontPattern = "JetBrainsMono Nerd Font"
#
#function Check-Font {
#    param (
#        [string]$path
#    )
#
#    try {
#        $installedFonts = Get-ItemProperty -Path $path -ErrorAction Stop |
#            Select-Object -Property PSChildName
#
#        $fontInstalled = $installedFonts.PSChildName -like "*$fontPattern*"
#        
#        return $fontInstalled -ne $null
#    } catch {
#        Write-Warning "Failed to read from $path"
#        return $false
#    }
#}
#
#$fontPaths = @(
#    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
#    "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
#)
#
#$font_found = $false
#
#foreach ($path in $fontPaths) {
#    if (Check-Font -path $path) {
#        $font_found = $true
#		Write-Output "'$fontPattern' found in $path."
#        break
#    }
#}
#
#if ($font_found) {
#    Write-Output "The font '$fontPattern' is installed."
#} else {
#    Write-Output "The font '$fontPattern' is not installed."
#}
#
#$fontReplaced = $false
#$alacrittyConfigFile = ".\alacritty\alacritty.toml"
#$oldFontName = "JetBrainsMono NF"
#$newFontName = "JetBrainsMono Nerd Font" # With spaces
#
#if ($nerdFonts.Count -gt 0 -or $nerdFontsAlt.Count -gt 0 -or $font_found) {
#    if (Test-Path $alacrittyConfigFile) {
#        Replace-FontName -filePath $alacrittyConfigFile -oldFontName $oldFontName -newFontName $newFontName
#        Write-Host "Replaced '$oldFontName' with '$newFontName' in $alacrittyConfigFile"
#        $fontReplaced = $true
#    } else {
#        Write-Host "$alacrittyConfigFile not found."
#    }
#} else {
#    Write-Host "No JetBrainsMonoNerdFont* files found in $fontsDir"
#}

# Just check the pwsh settings.json...

$settingsPath = (Get-Item "C:\users\$env:UserName\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json").FullName
$settingsContent = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
$fontName = $settingsContent.profiles.defaults.font.face

if ($fontName -eq "JetBrainsMono Nerd Font") {
    Write-Output "Font is set to JetBrainsMono Nerd Font"
} elseif ($fontName -eq "JetBrainsMono NF") {
    Write-Output "Font is set to JetBrainsMono NF"
} else {
    Write-Output "Font wasn't found in profiles.defaults.font.face. Checking file for JetBrainsMono*..."
    $settingsContent = Get-Content -Path $settingsPath -Raw
    if ($settingsContent -match "JetBrainsMono\s*(Nerd Font|NF)") {
        $match = $matches[0]
            if ($match -match "Nerd Font") {
                Write-Output "Font is set to JetBrainsMono Nerd Font (second check)"
            } elseif ($match -match "NF") {
                Write-Output "Font is set to JetBrainsMono NF (second check)"
            }
    } else {
        Write-Output "No JetBrainsMono font found in the settings."
    }
}

