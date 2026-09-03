$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set."
    exit 1
}

#python "$notes/scripts/files/open_ssms_as_user.py"
# Forward all script arguments to python
python "$notes/scripts/files/open_ssms_as_user.py" @args
