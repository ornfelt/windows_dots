$colors = @(
    "Black",
    "DarkBlue",
    "DarkGreen",
    "DarkCyan",
    "DarkRed",
    "DarkMagenta",
    "DarkYellow",
    "Gray",
    "DarkGray",
    "Blue",
    "Green",
    "Cyan",
    "Red",
    "Magenta",
    "Yellow",
    "White"
)

foreach ($color in $colors) {
    Write-Host "$color" -ForegroundColor $color
}

