$notes = $env:my_notes_path

if ([string]::IsNullOrWhiteSpace($notes)) {
    Write-Host "Environment variable 'my_notes_path' is not set."
    exit 1
}

#python "$notes/scripts/files/arg_tests/client_arg_tests.py"
# Forward all script arguments to python
python "$notes/scripts/files/arg_tests/client_arg_tests.py" @args
