# setup.ps1 - sets up a new machine from a mounted HDD (the reverse of {my_notes_path}/sync_hdd.ps1).
#
# Finds a mounted drive holding my_files\my_docs\local (D:\, E:\, ... any letter) and then:
#   - copies env_DESKTOP-I3H2E12.ps1 to $env:ps_profile_path\env.ps1, unless env.ps1 exists
#   - copies config_DESKTOP-I3H2E12.txt to C:\local\config.txt, unless it exists
#   - copies sqls_config_DESKTOP-I3H2E12.txt to C:\local\sqls_config.txt, unless it exists
#   - copies my_files\my_docs\img\Wallpapers into ~\Pictures\Wallpapers, only the files missing there
#
# Usage examples:
# .\setup.ps1            # do the setup
# .\setup.ps1 -WhatIf    # only print what would be copied

[CmdletBinding(SupportsShouldProcess)]
param()

function Write-Ok     ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err    ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn   ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info   ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt([string]$m) { Write-Host $m -ForegroundColor Magenta }

# Constants
$HDD_DOCS_SUBPATH  = 'my_files\my_docs'
$HDD_LOCAL_SUBPATH = "$HDD_DOCS_SUBPATH\local"
$HDD_WALLPAPERS    = "$HDD_DOCS_SUBPATH\img\Wallpapers"
$LOCAL_BASE        = 'C:\local'
$ENV_SOURCE_PC     = 'DESKTOP-I3H2E12'
$CONFIG_SOURCE_PC  = 'DESKTOP-I3H2E12'
$PICTURES_DIR      = Join-Path $env:USERPROFILE 'Pictures'
# Mounted drives that are searched (network drives are skipped: they can hang when offline)
$HDD_DRIVE_TYPES   = @([System.IO.DriveType]::Fixed, [System.IO.DriveType]::Removable)

# Discover mounted HDDs
Write-Info "Scanning for mounted HDDs..."

$systemDrive = "$env:SystemDrive\"
$hddRoot = $null
foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
    if (-not $drive.IsReady -or ($HDD_DRIVE_TYPES -notcontains $drive.DriveType) -or ($drive.Name -eq $systemDrive)) {
        continue
    }
    $hddLocal = Join-Path $drive.Name $HDD_LOCAL_SUBPATH
    if (Test-Path -LiteralPath $hddLocal -PathType Container) {
        Write-Ok "  [FOUND] $($drive.Name) -> $hddLocal"
        if (-not $hddRoot) { $hddRoot = $drive.Name }
    } else {
        Write-Warn "  [SKIP]  $($drive.Name) is mounted but '$hddLocal' does not exist"
    }
}

if (-not $hddRoot) {
    Write-Err "No mounted HDD with <drive>:\$HDD_LOCAL_SUBPATH found. Exiting."
    exit 1
}

$hddLocalDir = Join-Path $hddRoot $HDD_LOCAL_SUBPATH
Write-InfoAlt "Using HDD: $hddRoot"

# Copies Src to Dest unless Dest already exists
function Copy-IfMissing([string]$Src, [string]$Dest) {
    if (Test-Path -LiteralPath $Dest) {
        Write-Info "  [EXISTS] $Dest - left as is"
        return
    }
    if (-not (Test-Path -LiteralPath $Src -PathType Leaf)) {
        Write-Warn "  [SKIP]   Source not found: $Src"
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Dest, "Copy $Src")) { return }
    try {
        $destDir = Split-Path -Path $Dest -Parent
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Write-Info "  [MKDIR]  $destDir"
        }
        Copy-Item -LiteralPath $Src -Destination $Dest
        Write-Ok "  [OK]     $Src -> $Dest"
    } catch {
        Write-Err "  [ERR]    Failed to copy $Src -> $Dest`n           $_"
    }
}

# env.ps1
Write-Info ""
Write-Info "Copying env.ps1..."
$psProfilePath = $env:ps_profile_path
if (-not $psProfilePath) {
    Write-Warn "  [WARN] `$env:ps_profile_path is not set - skipping env.ps1 copy"
} else {
    Copy-IfMissing -Src (Join-Path $hddLocalDir "env_$ENV_SOURCE_PC.ps1") -Dest (Join-Path $psProfilePath 'env.ps1')
}

# Config files
Write-Info ""
Write-Info "Copying config files..."
foreach ($baseName in @('config', 'sqls_config')) {
    Copy-IfMissing -Src (Join-Path $hddLocalDir "${baseName}_$CONFIG_SOURCE_PC.txt") -Dest (Join-Path $LOCAL_BASE "$baseName.txt")
}

# Wallpapers: copy only the files missing locally, existing ones are never overwritten
Write-Info ""
Write-Info "Copying wallpapers..."
$hddWallpapers   = Join-Path $hddRoot $HDD_WALLPAPERS
$localWallpapers = Join-Path $PICTURES_DIR (Split-Path -Path $HDD_WALLPAPERS -Leaf)
if (-not (Test-Path -LiteralPath $hddWallpapers -PathType Container)) {
    Write-Warn "  [SKIP] HDD dir not found: $hddWallpapers"
} else {
    # /XC /XN /XO: skip files that already exist locally (changed, newer or older)
    $robocopyArgs = @($hddWallpapers, $localWallpapers, '/E', '/XC', '/XN', '/XO', '/NDL', '/NJH', '/NJS', '/NP')
    if (-not $PSCmdlet.ShouldProcess($localWallpapers, "Copy missing files from $hddWallpapers")) {
        # List only (/L), so -WhatIf shows which files would be copied
        robocopy @robocopyArgs /L
    } else {
        robocopy @robocopyArgs
        # robocopy exit codes below 8 mean success
        if ($LASTEXITCODE -ge 8) {
            Write-Err "  [ERR] Copying $hddWallpapers -> $localWallpapers failed (robocopy exit code $LASTEXITCODE)"
        } elseif ($LASTEXITCODE -eq 0) {
            Write-Info "  [OK]  $localWallpapers already has every file"
        } else {
            Write-Ok "  [OK]  $hddWallpapers -> $localWallpapers"
        }
    }
}

Write-Info ""
Write-Ok "Done."
# Don't let robocopy's success codes (1-7) leak out as the script's exit code
exit 0
