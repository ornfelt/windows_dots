$path = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Python\my_py\bookshelf"

if (Test-Path $path) {
    cd $path
} else {
    Write-Host "Couldn't find bookshelf path." -ForegroundColor Red
    exit 1
}

echo "Usage examples:"
echo "python app.py"
