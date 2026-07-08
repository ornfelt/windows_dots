$path = Join-Path -Path $env:code_root_dir -ChildPath "Code2\Javascript\my_js\geo-quiz"

if (Test-Path $path) {
    cd $path
} else {
    Write-Host "Couldn't find geo-quiz path." -ForegroundColor Red
    exit 1
}

echo "Usage examples:"
echo "npm run dev"
