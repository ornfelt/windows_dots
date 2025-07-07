# Ensure the WOW Classic directory exists
if (-not (Test-Path $env:wow_classic_dir)) {
    Write-Host "ERROR: Wow Classic directory not found: $($env:wow_classic_dir)" -ForegroundColor Red
    exit 1
}
Write-Host "Using wow_classic_dir: $($env:wow_classic_dir)"

# Get and print the current UserDomain
$userDomain = $env:UserDomain
Write-Host "User Domain: $userDomain"

# Build paths
$sourceWtfDir  = Join-Path $env:wow_classic_dir 'WTF'
$sourceConfig  = Join-Path $sourceWtfDir 'Config.wtf'
$sourceAccount = Join-Path $sourceWtfDir 'Account'

$destRoot      = Join-Path $env:code_root_dir  'Code2\Wow\addons\wow_addons\classic\WTF'
$destConfig    = Join-Path $destRoot      ("${userDomain}_Config.wtf")
$destAccount   = Join-Path $destRoot      'Account'

# Ensure destination exists
if (-not (Test-Path $destRoot)) {
    Write-Host "ERROR: Destination directory not found: $destRoot" -ForegroundColor Red
    exit 1
}

# Copy Config.wtf with domain prefix
if (-not (Test-Path $sourceConfig)) {
    Write-Host "ERROR: Source Config.wtf not found: $sourceConfig" -ForegroundColor Red
    exit 1
}
Copy-Item -Path $sourceConfig -Destination $destConfig -Force
Write-Host "Copied Config.wtf -> $destConfig"

# Replace the Account folder
if (Test-Path $sourceAccount) {
    # Remove existing
    if (Test-Path $destAccount) {
        Remove-Item -Path $destAccount -Recurse -Force
        Write-Host "Removed existing Account folder at $destAccount"
    }
    # Copy new
    Copy-Item -Path $sourceAccount -Destination $destRoot -Recurse -Force
    Write-Host "Copied Account folder -> $destAccount"
}
else {
    Write-Host "WARNING: Source Account folder not found: $sourceAccount" -ForegroundColor Yellow
}

Write-Host "Done."

