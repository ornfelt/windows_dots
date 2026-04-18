function Write-Ok      ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err     ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn    ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info    ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt ([string]$m) { Write-Host $m -ForegroundColor Magenta }

$n = 0

Write-Info "n = $n"

if ($args.Count -gt 0) {
    Write-InfoAlt "Print mode enabled because an argument was provided."
    Write-Host "git log -1 --skip=$n --pretty=%s | Set-Clipboard"
}
else {
    Write-Ok "Running command..."

    # Capture output as a single string and trim trailing newline(s)
    $text = (git log -1 --skip=$n --pretty=%s | Out-String).TrimEnd("`r", "`n")

    # Copy cleaned text to clipboard
    $text | Set-Clipboard

    Write-Ok "Copied commit subject to clipboard."
}
