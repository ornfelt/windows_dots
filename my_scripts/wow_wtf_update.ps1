#param(
#    [ValidateSet('wotlk','tbc','classic')]
#    [string]$version = 'wotlk'
#)
#
#switch ($version) {
#    'wotlk' {
#        $wowEnv      = 'wow_dir'
#        $addonSubDir = 'wotlk\WTF'
#    }
#    'tbc' {
#        $wowEnv      = 'wow_tbc_dir'
#        $addonSubDir = 'tbc\WTF'
#    }
#    'classic' {
#        $wowEnv      = 'wow_classic_dir'
#        $addonSubDir = 'classic\WTF'
#    }
#}

# Use args instead of param...
if ($args.Count -ge 1) {
    $ver = $args[0].ToLower()
} else {
    #$ver = 'classic'
    #$ver = 'tbc'
    $ver = 'wotlk'
}

switch ($ver) {
    'wotlk' {
        $wowEnv      = 'wow_dir'
        $addonSubDir = 'wotlk\WTF'
    }
    'tbc' {
        $wowEnv      = 'wow_tbc_dir'
        $addonSubDir = 'tbc\WTF'
    }
    'classic' {
        $wowEnv      = 'wow_classic_dir'
        $addonSubDir = 'classic\WTF'
    }
    default {
        Write-Host "ERROR: Unknown version '$ver'. Valid values are wotlk, tbc, classic." -ForegroundColor Red
        exit 1
    }
}

# Resolve the root paths
$wowRoot   = (Get-Item "env:$wowEnv").Value
$destRoot  = Join-Path $env:code_root_dir "Code2\Wow\addons\wow_addons\$addonSubDir"

# Ensure the WOW directory exists
if (-not (Test-Path $wowRoot)) {
    Write-Host "ERROR: Wow directory not found: $wowRoot" -ForegroundColor Red
    exit 1
}
Write-Host "Using ${wowEnv} ($ver): $wowRoot"

# Get and print the current UserDomain
$userDomain = $env:UserDomain
Write-Host "User Domain: $userDomain"

# Build source paths
$sourceWtfDir  = Join-Path $wowRoot 'WTF'
$sourceConfig  = Join-Path $sourceWtfDir 'Config.wtf'
$sourceAccount = Join-Path $sourceWtfDir 'Account'

# Ensure destination exists
if (-not (Test-Path $destRoot)) {
    Write-Host "ERROR: Destination directory not found: $destRoot" -ForegroundColor Red
    exit 1
}

# Copy Config.wtf with domain prefix
$destConfig = Join-Path $destRoot ("${userDomain}_Config.wtf")
if (-not (Test-Path $sourceConfig)) {
    Write-Host "ERROR: Source Config.wtf not found: $sourceConfig" -ForegroundColor Red
    exit 1
}
Copy-Item -Path $sourceConfig -Destination $destConfig -Force
Write-Host "Copied Config.wtf -> $destConfig"

# Replace the Account folder
$destAccount = Join-Path $destRoot 'Account'
if (Test-Path $sourceAccount) {
    if (Test-Path $destAccount) {
        Remove-Item -Path $destAccount -Recurse -Force
        Write-Host "Removed existing Account folder at $destAccount"
    }
    Copy-Item -Path $sourceAccount -Destination $destRoot -Recurse -Force
    Write-Host "Copied Account folder -> $destAccount"
}
else {
    Write-Host "WARNING: Source Account folder not found: $sourceAccount" -ForegroundColor Yellow
}

Write-Host "Done."

