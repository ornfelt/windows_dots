# opend2.ps1 - runs OpenDiablo2 ($env:code_root_dir/Code2/Go/OpenDiablo2) with config.json's MpqPath
# pointing at a local d2 dir (<d2 dir>/d2video holds the MPQs).
#
# Usage example (no args):
# .opend2
#
# The d2 dir is $env:USERPROFILE\Downloads\d2. When it does not exist, it is copied there from a
# mounted drive (D:\2024\d2, E:\2024\d2, ...) when there is room for it plus a 5 GB margin.

function Write-Label($text) { Write-Host "$text" -ForegroundColor DarkGray }
function Write-Info ($text) { Write-Host "$text" -ForegroundColor Cyan }
function Write-Warn ($text) { Write-Host "$text" -ForegroundColor DarkYellow }
function Write-Ok   ($text) { Write-Host "$text" -ForegroundColor Green }
function Write-Err  ($text) { Write-Host "$text" -ForegroundColor Red }

$codeRootDir = $env:code_root_dir
if (-not $codeRootDir) {
    $codeRootDir = $env:USERPROFILE
}

$OPEND2_DIR = Join-Path -Path $codeRootDir -ChildPath "Code2\Go\OpenDiablo2"
$OPEND2_EXE = "OpenDiablo2.exe"
$CONFIG_FILE = Join-Path -Path $env:APPDATA -ChildPath "OpenDiablo2\config.json"
$D2_DIR_NAME = "d2"
$MPQ_SUBDIR = "d2video"
$DOWNLOADS_DIR = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
$HDD_D2_SUBPATH = "2024\$D2_DIR_NAME"
$SPACE_MARGIN_BYTES = 5GB
# Mounted drives that are searched for 2024\d2 (network drives are skipped: they can hang when offline)
$HDD_DRIVE_TYPES = @([System.IO.DriveType]::Fixed, [System.IO.DriveType]::Removable)

# Local d2 dirs, checked in this order
$DIABLO_DIRS = @(
    (Join-Path -Path $DOWNLOADS_DIR -ChildPath $D2_DIR_NAME)
)

function Format-Size([long]$bytes) {
    if ($bytes -ge 1GB) { return "{0:N1} GB" -f ($bytes / 1GB) }
    return "{0:N0} MB" -f ($bytes / 1MB)
}

# Forward slashes, like OpenDiablo2 writes its paths, and nothing to escape in the json
function ConvertTo-ConfigPath([string]$path) {
    return $path.Replace('\', '/').TrimEnd('/')
}

$exePath = Join-Path -Path $OPEND2_DIR -ChildPath $OPEND2_EXE
if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
    Write-Err "$exePath does not exist. Build it first:"
    Write-Info "cd $OPEND2_DIR; go build"
    exit 1
}

$d2Dir = $DIABLO_DIRS | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -First 1

# Not found locally: copy it from a mounted drive into $DOWNLOADS_DIR
if (-not $d2Dir) {
    Write-Warn "No local Diablo 2 directory found (checked: $($DIABLO_DIRS -join ', ')). Looking on mounted drives..."

    $systemDrive = "$env:SystemDrive\"
    $hddCandidates = [System.IO.DriveInfo]::GetDrives() |
        Where-Object { $_.IsReady -and ($HDD_DRIVE_TYPES -contains $_.DriveType) -and ($_.Name -ne $systemDrive) } |
        ForEach-Object { Join-Path -Path $_.Name -ChildPath $HDD_D2_SUBPATH }
    $hddD2Dir = $hddCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -First 1

    if (-not $hddD2Dir) {
        Write-Err "No Diablo 2 directory found locally ($($DIABLO_DIRS -join ', ')) or on a mounted drive (<drive>:\$HDD_D2_SUBPATH)."
        exit 1
    }

    if (-not (Test-Path -LiteralPath $DOWNLOADS_DIR -PathType Container)) {
        New-Item -ItemType Directory -Path $DOWNLOADS_DIR | Out-Null
    }
    $d2Size = (Get-ChildItem -LiteralPath $hddD2Dir -Recurse -File -Force | Measure-Object -Property Length -Sum).Sum
    if (-not $d2Size) { $d2Size = 0 }
    $freeSpace = (New-Object System.IO.DriveInfo (Split-Path -Path $DOWNLOADS_DIR -Qualifier)).AvailableFreeSpace
    $neededSpace = $d2Size + $SPACE_MARGIN_BYTES
    Write-Label "Found $hddD2Dir ($(Format-Size $d2Size)). Free in ${DOWNLOADS_DIR}: $(Format-Size $freeSpace), needed (+$(Format-Size $SPACE_MARGIN_BYTES) margin): $(Format-Size $neededSpace)"

    if ($freeSpace -lt $neededSpace) {
        Write-Err "Not enough disk space to copy $hddD2Dir into $DOWNLOADS_DIR."
        exit 1
    }

    # Copy into a temporary dir first, so an interrupted copy never looks like a complete d2 dir
    $d2Dir = Join-Path -Path $DOWNLOADS_DIR -ChildPath $D2_DIR_NAME
    $partialDir = "$d2Dir.partial"
    if (Test-Path -LiteralPath $partialDir) {
        Write-Warn "Removing the leftover $partialDir of an interrupted copy"
        Remove-Item -LiteralPath $partialDir -Recurse -Force -Confirm:$false
    }
    Write-Info "Copying $hddD2Dir into $d2Dir..."
    robocopy $hddD2Dir $partialDir /E /NDL /NJH /NJS
    # robocopy exit codes below 8 mean success
    if ($LASTEXITCODE -ge 8) {
        Write-Err "Copying $hddD2Dir into $partialDir failed (robocopy exit code $LASTEXITCODE)."
        exit 1
    }
    Rename-Item -LiteralPath $partialDir -NewName $D2_DIR_NAME
    Write-Ok "Copied $hddD2Dir into $d2Dir"
}

$mpqPath = ConvertTo-ConfigPath (Join-Path -Path $d2Dir -ChildPath $MPQ_SUBDIR)
Write-Label "Using Diablo 2 directory: $d2Dir"

# Point config.json's MpqPath at it, unless it already does
if (Test-Path -LiteralPath $CONFIG_FILE -PathType Leaf) {
    $mpqPathPattern = '"MpqPath"\s*:\s*"([^"]*)"'
    $config = [System.IO.File]::ReadAllText($CONFIG_FILE)
    $match = [regex]::Match($config, $mpqPathPattern)
    if (-not $match.Success) {
        Write-Warn "$CONFIG_FILE has no MpqPath entry - not updated."
    } elseif ((ConvertTo-ConfigPath $match.Groups[1].Value) -eq $mpqPath) {
        Write-Label "config.json MpqPath is already $mpqPath"
    } else {
        $config = $config.Remove($match.Index, $match.Length).Insert($match.Index, "`"MpqPath`": `"$mpqPath`"")
        # No BOM: OpenDiablo2's json parser rejects one
        [System.IO.File]::WriteAllText($CONFIG_FILE, $config, (New-Object System.Text.UTF8Encoding $false))
        Write-Ok "Updated config.json MpqPath: $($match.Groups[1].Value) -> $mpqPath"
    }
} else {
    Write-Warn "$CONFIG_FILE does NOT exist yet. OpenDiablo2 has not been run yet - run this again after its first run to set MpqPath."
}

Set-Location -Path $OPEND2_DIR
& ".\$OPEND2_EXE"
