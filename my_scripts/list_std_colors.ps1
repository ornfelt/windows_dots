$esc = [char]27
$reset = "$esc[0m"

# List standard asci colors

Write-Host "=== Standard 16 ANSI foreground colors (30-37, 90-97) ===`n"

$standardColors = @(
    @{ Code = 30; Name = "Black";          Kind = "Normal" }
    @{ Code = 31; Name = "Red";            Kind = "Normal" }
    @{ Code = 32; Name = "Green";          Kind = "Normal" }
    @{ Code = 33; Name = "Yellow";         Kind = "Normal" }
    @{ Code = 34; Name = "Blue";           Kind = "Normal" }
    @{ Code = 35; Name = "Magenta";        Kind = "Normal" }
    @{ Code = 36; Name = "Cyan";           Kind = "Normal" }
    @{ Code = 37; Name = "White/Gray";     Kind = "Normal" }

    @{ Code = 90; Name = "Bright Black";   Kind = "Bright" }
    @{ Code = 91; Name = "Bright Red";     Kind = "Bright" }
    @{ Code = 92; Name = "Bright Green";   Kind = "Bright" }
    @{ Code = 93; Name = "Bright Yellow";  Kind = "Bright" }
    @{ Code = 94; Name = "Bright Blue";    Kind = "Bright" }
    @{ Code = 95; Name = "Bright Magenta"; Kind = "Bright" }
    @{ Code = 96; Name = "Bright Cyan";    Kind = "Bright" }
    @{ Code = 97; Name = "Bright White";   Kind = "Bright" }
)

foreach ($c in $standardColors) {
    $seq   = "$esc[$($c.Code)m"
    $label = "{0,3}" -f $c.Code
    $line  = "{0} ({1,-6} {2,-13})" -f $label, $c.Kind, $c.Name
    Write-Host "$line " -NoNewline
    Write-Host "$seq Sample text $reset"
}

Write-Host "`n`n=== 256-color palette (0-255) ===`n"

for ($i = 0; $i -lt 256; $i++) {
    # Background using 256-color
    $code  = "$esc[48;5;${i}m"
    $label = "{0,3}" -f $i
    Write-Host "$code $label $reset " -NoNewline

    if (($i + 1) % 16 -eq 0) {
        Write-Host ""
    }
}

Write-Host "`n`n=== Truecolor (24-bit RGB) demo (38;2;R;G;B) ===`n"

# Just a small grid so it doesn't spam the whole screen
$steps = 0, 128, 255
foreach ($r in $steps) {
    foreach ($g in $steps) {
        foreach ($b in $steps) {
            $seq = "$esc[38;2;${r};${g};${b}m"
            $label = "R{0,3} G{1,3} B{2,3}" -f $r, $g, $b
            Write-Host "$seq$label$reset  " -NoNewline
        }
        Write-Host ""
    }
    Write-Host ""
}
