param (
    [string]$InputLine
)

# Usage examples:
# .\copy_path.ps1 C:\Users\jonas\OneDrive\Documents\my_notes\notes\
# .\copy_path.ps1 "C:\Users\jonas\OneDrive\Documents\my_notes\notes\" 1
# .\copy_path.ps1 "C:/Users/jonas\OneDrive\Documents\my_notes\notes\"
# .\copy_path.ps1 "{my_notes_path}\notes"
# .\copy_path.ps1 "{my_notes_path}\notes" 1
# .\copy_path.ps1 "C:/Users/jonas/Code/unity/quake3-movement-unity3d/CPMPlayer.js"
# .\copy_path.ps1 "{code_root_dir}/Code/yaml/PetStore/postgres_db_script"
# .\copy_path.ps1 "{code_root_dir}/Code/yaml/PetStore/postgres_db_script" 1

#$DebugPrints = $false
$DebugPrints = $true

function NormalizePath {
    param (
        [string]$Path
    )
    $Path = $Path -replace '\\', '/'  # Replace backslashes with slashes
    $Path = $Path -replace '//+', '/' # Remove consecutive slashes
    return $Path
}

$env:my_notes_path = NormalizePath $env:my_notes_path
$env:code_root_dir = NormalizePath $env:code_root_dir

if ($DebugPrints) { Write-Host "Debug: my_notes_path = '$env:my_notes_path'" }
if ($DebugPrints) { Write-Host "Debug: code_root_dir = '$env:code_root_dir'" }

if (-not $env:my_notes_path -or -not $env:code_root_dir) {
    Write-Host "Environment variables 'my_notes_path' or 'code_root_dir' are not set."
    exit 1
}

$usePsProfilePath = $false
if ($env:ps_profile_path) {
    $env:ps_profile_path = NormalizePath $env:ps_profile_path
    if ($DebugPrints) { Write-Host "Debug: ps_profile_path = '$env:ps_profile_path'" }
    $usePsProfilePath = $true
}

function Replace-Path-BasedOnContext {
    param (
        [string]$InputPath,
        [switch]$NoPlaceholders
    )

    $NormalizedCodeRootDir = NormalizePath "$env:code_root_dir"
    $NormalizedMyNotesPath = NormalizePath "$env:my_notes_path"
    $NormalizedPsProfilePath = NormalizePath "$env:ps_profile_path"

    if ($DebugPrints) {
        Write-Host "Debug: Normalized code_root_dir = '$NormalizedCodeRootDir'"
        Write-Host "Debug: Normalized my_notes_path = '$NormalizedMyNotesPath'"
        if ($usePsProfilePath) {
            Write-Host "Debug: Normalized ps_profile_path = '$NormalizedPsProfilePath'"
        }
    }

    if ($DebugPrints) { Write-Host "Debug: InputPath before replacement = '$InputPath'" }

    $InputPath = $InputPath -replace "^~/", "$env:HOME/"
    $InputPath = NormalizePath $InputPath

    if (-not $NoPlaceholders) {
        $InputPath = $InputPath -replace "{my_notes_path}", $NormalizedMyNotesPath
        $InputPath = $InputPath -replace "{code_root_dir}", $NormalizedCodeRootDir

        if ($DebugPrints) { Write-Host "Debug: InputPath after placeholder expansion = '$InputPath'" }
    }

    if ($NoPlaceholders) {
        $InputPath = $InputPath -replace [regex]::Escape($NormalizedMyNotesPath), "{my_notes_path}"

        $NormalizedCodeRootDirCheck = NormalizePath "$NormalizedCodeRootDir/Code*"

        if ($DebugPrints) { Write-Host "Debug: Checking if InputPath starts with '$NormalizedCodeRootDirCheck'" }
        if ($InputPath -like $NormalizedCodeRootDirCheck) {
            if ($DebugPrints) { Write-Host "Debug: Match found. Replacing '$NormalizedCodeRootDir' with '{code_root_dir}' in InputPath." }
            $InputPath = $InputPath -replace [regex]::Escape($NormalizedCodeRootDir), "{code_root_dir}/"
        } else {
            if ($DebugPrints) { Write-Host "Debug: No match found. InputPath remains unchanged." }
        }

        if ($usePsProfilePath) {
            $InputPath = $InputPath -replace [regex]::Escape($NormalizedPsProfilePath), "{ps_profile_path}"
        }

        if ($DebugPrints) { Write-Host "Debug: InputPath after reverse placeholder replacement = '$InputPath'" }
    }

    $InputPath = NormalizePath $InputPath
    return $InputPath
}

if (-not $InputLine) {
    Write-Host "Usage: .\CopyToClipboard.ps1 <input_line> [-NoPlaceholders]"
    exit 1
}

$NoPlaceholders = $true
if ($args.Count -ge 1) {
    $NoPlaceholders = $false
}

if ($DebugPrints) { Write-Host "Debug: Initial InputLine = '$InputLine'" }
if ($DebugPrints) { Write-Host "Debug: NoPlaceholders = '$NoPlaceholders'" }

$outputLine = Replace-Path-BasedOnContext -InputPath $InputLine -NoPlaceholders:$NoPlaceholders
if ($DebugPrints) { Write-Host "Debug: Final Processed OutputLine = '$outputLine'" }

Set-Clipboard -Value $outputLine

