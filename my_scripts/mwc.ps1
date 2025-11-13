$scriptPath = "$env:code_root_dir/Code2/Wow/tools/my_wow/cd_and_print.ps1"

if (Test-Path $scriptPath) {
    Write-Host "Running: & `$env:code_root_dir/Code2/Wow/tools/my_wow/cd_and_print.ps1 $args" -ForegroundColor Cyan
    # splat the args
    & $scriptPath @args
} else {
    Write-Host "Script not found: $scriptPath" -ForegroundColor Red
}

