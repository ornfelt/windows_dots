if (Test-Path "C:\Users\jonas\Code2\C++\acore\azerothcore-wotlk\build_eluna\bin\RelWithDebInfo") {
    $path = "C:\Users\jonas\Code2\C++\acore\azerothcore-wotlk\build_eluna\bin\RelWithDebInfo"
} elseif (Test-Path "D:\My files\svea_laptop\acore\azerothcore\build_eluna\bin\RelWithDebInfo") {
    $path = "D:\My files\svea_laptop\acore\azerothcore\build_eluna\bin\RelWithDebInfo"
} elseif (Test-Path "x") {
	$path = "x"
} else {
    $path = "~/acore/bin"
}

cd $path

#echo "$path\worldserver.exe"
#Invoke-Expression "$path\worldserver.exe"

echo "python $path\overwrite.py; $path\worldserver.exe"
#Invoke-Expression "python $path\overwrite.py; $path\worldserver.exe"