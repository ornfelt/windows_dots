$path = Join-Path -Path $env:my_notes_path -ChildPath "scripts\files\mov"
if (Test-Path $path) {
    cd $path
} else {
    Write-Host "Couldn't find mov path." -ForegroundColor Red
    exit 1
}
echo "Usage examples:"
echo "npm run start"
