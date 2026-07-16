# see:
# $env:my_notes_path/scripts/git_diff/git_diff.ps1
$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set." -ForegroundColor Red
    exit 1
}

$scriptPath = Join-Path $notes "scripts/git_diff/git_diff.ps1"

if (-not (Test-Path $scriptPath -PathType Leaf)) {
    Write-Host "git_diff.ps1 does not exist:" -ForegroundColor Red
    Write-Host "  $scriptPath"
    exit 1
}

& $scriptPath @args
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "git_diff.ps1 failed with exit code $exitCode." -ForegroundColor Red
    exit $exitCode
}

exit 0
