if (Test-Path "C:\mw\MSVC2022_64\RelWithDebInfo") {
    $path = "C:\mw\MSVC2022_64\RelWithDebInfo"
} elseif (Test-Path "D:\My_files\OpenMW\openmw\MSVC2022_64\RelWithDebInfo") {
    $path = "D:\My_files\OpenMW\openmw\MSVC2022_64\RelWithDebInfo"
} elseif (Test-Path "x") {
	$path = "x"
} else {
    $path = "~/"
}

#cd $path

#echo "$path\openmw.exe"
#Invoke-Expression "$path\openmw.exe"

echo "$path\openmw-launcher.exe"
Invoke-Expression "$path\openmw-launcher.exe"