function Write-Info($message) {
    Write-Host $message -ForegroundColor Cyan
}

function Write-Warn($message) {
    Write-Host $message -ForegroundColor Yellow
}

function Get-FirstFile($pattern) {
    Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

$solution =
    Get-FirstFile ".\*.sln"

if (-not $solution) {
    $solution = Get-FirstFile ".\*.slnx"
}

if (-not $solution) {
    $solution = Get-FirstFile ".\build\*.sln"
}

if (-not $solution) {
    $solution = Get-FirstFile ".\build\*.slnx"
}

if ($solution) {
    Write-Info "Opening solution:"
    Write-Info "  $($solution.FullName)"

    Start-Process $solution.FullName
}
else {
    Write-Warn "No .sln or .slnx file found in:"
    Write-Warn "  $(Get-Location)"
    Write-Warn "  $(Join-Path (Get-Location) 'build')"
}
