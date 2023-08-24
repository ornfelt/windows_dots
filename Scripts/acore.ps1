#$path = "C:\Users\jonas\Code2\C++\acore\azerothcore-wotlk\build\bin\RelWithDebInfo"
$path = "C:\Users\jonas\Code2\C++\acore\azerothcore-wotlk\build_eluna\bin\RelWithDebInfo"

cd $path

#echo "$path\worldserver.exe"
#Invoke-Expression "$path\worldserver.exe"

echo "python $path\overwrite.py; $path\worldserver.exe"
#Invoke-Expression "python $path\overwrite.py; $path\worldserver.exe"