$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\TrinityCore-3.3.5-with-NPCBots"

cd $basePath
Write-Output "Performing git pull in $basePath"
git pull

Write-Output "`nCompleted git pull in $basePath"

