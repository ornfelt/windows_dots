$esc = [char]27
$reset = "$esc[0m"

for ($i = 0; $i -lt 256; $i++) {
    # Background color using ANSI 256-color
    $code = "$esc[48;5;${i}m"
    $label = "{0,3}" -f $i  # right-aligned number

    Write-Host "$code $label $reset " -NoNewline

    if (($i + 1) % 16 -eq 0) {
        Write-Host ""
    }
}

Write-Host ""
