$path = Join-Path -Path $env:my_notes_path -ChildPath "scripts\files\mov_py"

if (Test-Path $path) {
    cd $path
} else {
    Write-Host "Couldn't find mov_py path." -ForegroundColor Red
    exit 1
}

echo "Usage examples:"
echo "python app.py"
