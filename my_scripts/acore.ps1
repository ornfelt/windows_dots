$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\AzerothCore-wotlk-with-NPCBots\build\bin\RelWithDebInfo"

if (Test-Path $basePath) {
    $path = $basePath
} elseif (Test-Path "D:\My files\svea_laptop\acore\azerothcore\build_eluna\bin\RelWithDebInfo") {
    $path = "D:\My files\svea_laptop\acore\azerothcore\build_eluna\bin\RelWithDebInfo"
} else {
    $path = "~/acore/bin"
}

cd $path

#echo "$path\worldserver.exe"
#Invoke-Expression "$path\worldserver.exe"

echo "python $path\overwrite.py; $path\worldserver.exe"
#Invoke-Expression "python $path\overwrite.py; $path\worldserver.exe"

