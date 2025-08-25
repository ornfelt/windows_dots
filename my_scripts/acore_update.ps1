#
# Update AzerothCore and mod-eluna
#
$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\AzerothCore-wotlk-with-NPCBots"
$modulesPath = Join-Path -Path $basePath -ChildPath "modules"
$elunaPath = Join-Path -Path $modulesPath -ChildPath "mod-eluna"

# Usage:
# .\acore_update.ps1
# Skip mod-eluna commit alignment
# .\acore_update.ps1 1

#Set-Location $basePath
cd $basePath
Write-Output "Performing git pull in $basePath"
git pull

# Check if modules dir exists
if (-Not (Test-Path -Path $modulesPath)) {
    Write-Output "Modules directory not found: $modulesPath"
    exit 1
}

# Perform git pull in each immediate subdirectory inside modules
foreach ($subdir in Get-ChildItem -Path $modulesPath -Directory) {
    $subdirPath = $subdir.FullName

    # Check if subdir is a git repo
    if (-Not (Test-Path -Path (Join-Path -Path $subdirPath -ChildPath ".git"))) {
        Write-Output "Skipping non-Git directory: $subdirPath"
        continue
    }

    # Navigate into subdir and do git pull
    cd $subdirPath

    #Write-Output ""
    #Write-Output "`nPerforming git pull in $subdirPath"
    #git pull
    if ($subdirPath -match "mod-eluna") {
        Write-Output "`nPerforming specific git pull for mod-eluna in $subdirPath"
        git pull https://github.com/azerothcore/mod-eluna master
    } else {
        Write-Output "`nPerforming git pull in $subdirPath"
        git pull
    }
}

cd $basePath
#Set-Location $basePath

Write-Output "`nCompleted git pull in all directories."
#Write-Output "`n***If you need to specify branch for eluna, do: git pull https://github.com/azerothcore/mod-eluna master"

#
# Also determine latest nonmmerge AzerothCore commit
#
if ($args.Count -eq 0) {
    Write-Output "`nFinding latest AzerothCore commit that is NOT a merge and NOT containing 'Merge branch'..."

    # Format: <sha>|<iso_date>|<subject>
    $acoreInfo = git log --no-merges --regexp-ignore-case --invert-grep --grep='Merge branch' -1 --format='%H|%cI|%s'
    if (-not $acoreInfo) {
        Write-Output "Could not find a matching AzerothCore commit. Aborting eluna alignment."
        Write-Output "`nCompleted git pull in all directories."
        exit 0
    }

    $acoreParts = $acoreInfo -split '\|',3
    $acoreSha = $acoreParts[0]
    $acoreIso = $acoreParts[1]
    $acoreSubj = $acoreParts[2]
    # Use DateTimeOffset for robust TZ-aware comparisons
    $acoreDate = [datetimeoffset]::Parse($acoreIso)

    Write-Output "AzerothCore latest non-merge commit:"
    Write-Output "  SHA:   $acoreSha"
    Write-Output "  Date:  $acoreDate"
    Write-Output "  Title: $acoreSubj"

    # Check mod-eluna state and potentially checkout a prior commit
    if (-not (Test-Path $elunaPath)) {
        Write-Output "mod-eluna directory not found at $elunaPath; skipping eluna alignment."
        Write-Output "`nCompleted git pull in all directories."
        exit 0
    }

    Set-Location $elunaPath

    # Make sure history is up to date (even if pull above skipped for any reason)
    git fetch --all --tags | Out-Null

    $elunaHeadSha = (git rev-parse HEAD).Trim()
    $elunaHeadIso = (git show -s --format=%cI HEAD).Trim()
    $elunaHeadDate = [datetimeoffset]::Parse($elunaHeadIso)

    Write-Output "`nmod-eluna HEAD:"
    Write-Output "  SHA:  $elunaHeadSha"
    Write-Output "  Date: $elunaHeadDate"

    # If eluna is already older (or equal) than the AzerothCore date -> bail
    if ($elunaHeadDate -le $acoreDate) {
        Write-Output "[ok] mod-eluna is already older than or equal to AzerothCore's target date. No checkout needed."
    } else {
        Write-Output "mod-eluna is NEWER than AzerothCore's target date."
        Write-Output "Searching for the latest mod-eluna commit BEFORE $acoreDate ..."

        # Find latest eluna commit strictly before the AzerothCore date
        $targetSha = (git log --before=$acoreIso -1 --format=%H).Trim()

        if ($null -ne $targetSha -and $targetSha -ne "") {
            $targetIso  = (git show -s --format=%cI $targetSha).Trim()
            $targetDate = [datetimeoffset]::Parse($targetIso)

            Write-Output "Found mod-eluna target commit:"
            Write-Output "  SHA:  $targetSha"
            Write-Output "  Date: $targetDate"
            Write-Output "Checking out mod-eluna commit $targetSha ..."
            git checkout $targetSha
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to checkout $targetSha"
                exit 1
            }
            Write-Output "mod-eluna aligned to commit prior to AzerothCore's target date."
        } else
        {
            Write-Output "No mod-eluna commit found prior to $acoreDate. Leaving mod-eluna at HEAD."
        }
    }

    Set-Location $basePath
    Write-Output "`nCompleted eluna alignment step."
} else {
    Write-Output "Skipping mod-eluna commit alignment since argument was passed."
}

