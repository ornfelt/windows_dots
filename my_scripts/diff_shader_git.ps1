#!/usr/bin/env pwsh
# Run diff_shader_git.py (diff_gfx.py) with all arguments forwarded.

# see usage examples in py script:
# {code_root_dir}/Code2/General/gfx/wc_compiler_test/diff_shader_git.py

$ErrorActionPreference = "Stop"

# Check env var
$codeRoot = $env:code_root_dir
if (-not $codeRoot) {
    Write-Host "ERROR: Environment variable 'code_root_dir' is not set." -ForegroundColor Red
    exit 1
}

# Check python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "ERROR: 'python' not found on PATH." -ForegroundColor Red
    exit 1
}
Write-Host "Using python: $($python.Source)" -ForegroundColor DarkGray

# Check script
$script = Join-Path $codeRoot "Code2/General/gfx/wc_compiler_test/diff_shader_git.py"
if (-not (Test-Path $script)) {
    Write-Host "ERROR: Script not found: $script" -ForegroundColor Red
    exit 1
}

# Run
Write-Host "Running: python $script $args" -ForegroundColor Cyan
& python $script @args
exit $LASTEXITCODE

