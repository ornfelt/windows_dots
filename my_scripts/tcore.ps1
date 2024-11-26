$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\TrinityCore-3.3.5-with-NPCBots\build\bin\RelWithDebInfo"

if (Test-Path $basePath) {
    $path = $basePath
} elseif (Test-Path "C:\Users\jonas\Code2\C++\tcore\trinitycore\build\bin\RelWithDebInfo") {
	$path = "C:\Users\jonas\Code2\C++\tcore\trinitycore\build\bin\RelWithDebInfo"
} elseif (Test-Path "D:\My files\svea_laptop\tcore\TrinityCore\build\bin\RelWithDebInfo") {
	$path = "D:\My files\svea_laptop\tcore\TrinityCore\build\bin\RelWithDebInfo"
} elseif (Test-Path "C:\Users\jonas\OneDrive\Documents\Code\tcore\TrinityCore\build\bin\RelWithDebInfo") {
	$path = "C:\Users\jonas\OneDrive\Documents\Code\tcore\TrinityCore\build\bin\RelWithDebInfo"
} else {
	$path = "~/"
}

cd $path

#echo "$path\worldserver.exe"
#Invoke-Expression "$path\worldserver.exe"

echo "python $path\overwrite.py; $path\worldserver.exe"
#Invoke-Expression "python $path\overwrite.py; $path\worldserver.exe"

