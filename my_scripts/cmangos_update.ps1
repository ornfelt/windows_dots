#
# Update mangos-classic or mangos-tbc and playerbots module
#
$ErrorActionPreference = "Stop"

$codeRoot = $env:code_root_dir
if ($args.Count -gt 0) {
    #$mangosDir = "mangos-$($args[0])"
    $mangosDir = "mangos-tbc"
} else {
    $mangosDir = "mangos-classic"
}

$basePath    = Join-Path -Path $codeRoot -ChildPath "Code2\C++\$mangosDir"
$modulesPath = Join-Path -Path $basePath -ChildPath "src\modules"
$playerBotsPath = Join-Path -Path $modulesPath -ChildPath "PlayerBots"

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

    if (-Not (Test-Path (Join-Path $subdirPath ".git"))) {
        Write-Output "Skipping non-Git directory: $subdirPath"
        continue
    }

    cd $subdirPath

    if ($subdirPath -match "PlayerBots") {
        Write-Output "`nPerforming git pull for PlayerBots in $subdirPath"
        git pull
    } else {
        Write-Output "`nPerforming git pull in $subdirPath"
        git pull
    }
}

cd $basePath
Write-Output "`nFinding latest mangos commit that is NOT a merge and NOT containing 'Merge branch'..."

$mainInfo = git log --no-merges --regexp-ignore-case --invert-grep --grep='Merge branch' -1 --format='%H|%cI|%s'
if (-not $mainInfo) {
    Write-Output "Could not find a matching mangos commit. Aborting PlayerBots alignment."
    exit 0
}

$mainParts = $mainInfo -split '\|',3
$mainSha   = $mainParts[0]
$mainIso   = $mainParts[1]
$mainSubj  = $mainParts[2]
$mainDate  = [datetimeoffset]::Parse($mainIso)

Write-Output "Mangos latest non-merge commit:"
Write-Output "  SHA:   $mainSha"
Write-Output "  Date:  $mainDate"
Write-Output "  Title: $mainSubj"

# Check PlayerBots state and potentially checkout a prior commit
if (-not (Test-Path $playerBotsPath)) {
    Write-Output "PlayerBots directory not found at $playerBotsPath; skipping alignment."
    exit 0
}

Set-Location $playerBotsPath
git fetch --all --tags | Out-Null

$botsSha  = (git rev-parse HEAD).Trim()
$botsIso  = (git show -s --format=%cI HEAD).Trim()
$botsDate = [datetimeoffset]::Parse($botsIso)

Write-Output "`nPlayerBots HEAD:"
Write-Output "  SHA:  $botsSha"
Write-Output "  Date: $botsDate"

if ($botsDate -le $mainDate) {
    Write-Output "[ok] PlayerBots is already older than or equal to mangos repo. No checkout needed."
} else {
    Write-Output "PlayerBots is NEWER than mangos repo."
    Write-Output "Searching for the latest PlayerBots commit BEFORE $mainDate ..."

    $targetSha = (git log --before=$mainIso -1 --format=%H).Trim()

    if ($null -ne $targetSha -and $targetSha -ne "") {
        $targetIso  = (git show -s --format=%cI $targetSha).Trim()
        $targetDate = [datetimeoffset]::Parse($targetIso)

        Write-Output "Found PlayerBots target commit:"
        Write-Output "  SHA:  $targetSha"
        Write-Output "  Date: $targetDate"
        Write-Output "Checking out PlayerBots commit $targetSha ..."
        git checkout $targetSha
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to checkout $targetSha"
            exit 1
        }
        Write-Output "PlayerBots aligned to commit prior to mangos repo target date."
    } else {
        Write-Output "No PlayerBots commit found prior to $mainDate. Leaving PlayerBots at HEAD."
    }
}

Set-Location $basePath
Write-Output "`nCompleted PlayerBots alignment step."

