$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set."
    exit 1
}

#python "$notes/scripts/pkg_helper.py"
# Forward all script arguments to python
python "$notes/scripts/pkg_helper.py" @args
