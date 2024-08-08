$fontPattern = "JetBrainsMono Nerd Font"

function Check-Font {
    param (
        [string]$path
    )

    try {
        $installedFonts = Get-ItemProperty -Path $path -ErrorAction Stop |
            Select-Object -Property PSChildName

        $fontInstalled = $installedFonts.PSChildName -like "*$fontPattern*"
        
        return $fontInstalled -ne $null
    } catch {
        Write-Warning "Failed to read from $path"
        return $false
    }
}

$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
    "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
)

$found = $false

foreach ($path in $paths) {
    if (Check-Font -path $path) {
        $found = $true
		Write-Output "'$fontPattern' found in $path."
        break
    }
}

if ($found) {
    Write-Output "The font '$fontPattern' is installed."
} else {
    Write-Output "The font '$fontPattern' is not installed."
}
