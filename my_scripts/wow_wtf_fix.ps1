# Basically the same as wow_wtf_update but it copies 
# in the other direction: from the repo to local wow dir.
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
$wowRoot = (Get-Item "env:$wowEnv").Value
$destRoot = Join-Path $env:code_root_dir "Code2\Wow\addons\wow_addons\$addonSubDir"

# Ensure both paths exist
if (-not (Test-Path $destRoot)) {
    Write-Host "ERROR: Source addon directory not found: $destRoot" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $wowRoot)) {
    Write-Host "ERROR: WoW directory not found: $wowRoot" -ForegroundColor Red
    exit 1
}

Write-Host "Copying Account folder FROM $destRoot TO $wowRoot"

# Paths
$sourceAccount = Join-Path $destRoot 'Account'
$targetWtfDir = Join-Path $wowRoot 'WTF'
$targetAccount = Join-Path $targetWtfDir 'Account'

# Ensure WTF folder exists at destination
if (-not (Test-Path $targetWtfDir)) {
    Write-Host "WTF directory not found at $targetWtfDir, creating it..."
    New-Item -ItemType Directory -Path $targetWtfDir | Out-Null
}

# Replace Account folder
if (Test-Path $sourceAccount) {
    if (Test-Path $targetAccount) {
        Remove-Item -Path $targetAccount -Recurse -Force
        Write-Host "Removed existing Account folder at $targetAccount"
    }
    Copy-Item -Path $sourceAccount -Destination $targetWtfDir -Recurse -Force
    Write-Host "Copied Account folder -> $targetAccount"
}
else {
    Write-Host "WARNING: Source Account folder not found: $sourceAccount" -ForegroundColor Yellow
}

Write-Host "Done."

