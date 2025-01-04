$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\AzerothCore-wotlk-with-NPCBots"

cd $basePath
Write-Output "Performing git pull in $basePath"
git pull

$modulesPath = Join-Path -Path $basePath -ChildPath "modules"

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
Write-Output "`nCompleted git pull in all directories."
#Write-Output "`n***If you need to specify branch for eluna, do: git pull https://github.com/azerothcore/mod-eluna master"

