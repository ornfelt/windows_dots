$scriptPath = "$env:code_root_dir/Code2/Wow/tools/my_wow/c++/tbc/run_with_args.ps1"

if (Test-Path $scriptPath) {
    Write-Host "Running: & `$env:code_root_dir/Code2/Wow/tools/my_wow/c++/tbc/run_with_args.ps1 1" -ForegroundColor Cyan
    & $scriptPath 1
} else {
    Write-Host "Script not found: $scriptPath" -ForegroundColor Red
}

