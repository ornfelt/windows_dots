$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set."
    exit 1
}

# Forward all script arguments to python
python "$notes/scripts/git_audit/module_sync_audit.py" @args
