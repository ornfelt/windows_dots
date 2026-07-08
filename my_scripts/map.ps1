$path = Join-Path -Path $env:my_notes_path -ChildPath "scripts\random\maps_data"

if (Test-Path $path) {
    cd $path
} else {
    Write-Host "Couldn't find maps_data path." -ForegroundColor Red
    exit 1
}

echo "Usage examples:"
echo "python app.py"
