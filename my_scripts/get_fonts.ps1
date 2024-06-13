# function Get-InstalledFonts {
#     # Using WMI to get the list of fonts
#     $fonts = Get-WmiObject -Query "SELECT * FROM Win32_FontInfoAction"
# 
#     # Create an array to store font names
#     $fontNames = @()
# 
#     # Loop through each font and extract the name
#     foreach ($font in $fonts) {
#         $fontNames += $font.FontTitle
#     }
# 
#     # Remove duplicates and sort the list
#     $fontNames = $fontNames | Sort-Object -Unique
# 
#     # Return the sorted list of font names
#     return $fontNames
# }
# 
# # Get the list of installed fonts and display them
# $installedFonts = Get-InstalledFonts
# 
# Write-Host "Installed Fonts:"
# $installedFonts | ForEach-Object { Write-Host $_ }

# Better to just check this dir: C:\Windows\Fonts
function Get-InstalledFonts {
    $fontDir = "C:\Windows\Fonts"
    #$fontFiles = Get-ChildItem -Path $fontDir -Filter "*.ttf", "*.otf", "*.fon"
    $fontFiles = Get-ChildItem -Path $fontDir

    # Create array to store font names
    $fontNames = @()

    # Loop through font files
    foreach ($fontFile in $fontFiles) {
        $fontNames += $fontFile.BaseName
    }

    # Remove duplicates and sort list
    $fontNames = $fontNames | Sort-Object -Unique

    # Return the sorted list of font names
    return $fontNames
}

# Get the list of installed fonts and display them
$installedFonts = Get-InstalledFonts

Write-Host "Installed Fonts:"
$installedFonts | ForEach-Object { Write-Host $_ }

