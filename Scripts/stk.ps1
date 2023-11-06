if (Test-Path "C:\Users\jonas\Code2\C++\stk\stk-code\build\bin\Release") {
	$path = "C:\Users\jonas\Code2\C++\stk\stk-code\build\bin\Release"
} elseif (Test-Path "D:\My files\svea_laptop\Downloads\SuperTuxKart-dev\stk-code\build\bin\Release") {
	$path = "D:\My files\svea_laptop\Downloads\SuperTuxKart-dev\stk-code\build\bin\Release"
} elseif (Test-Path "x") {
	$path = "x"
} else {
	$path = "~/"
}

#cd $path

#echo "$path\supertuxkart_original.exe"
#Invoke-Expression "$path\supertuxkart_original.exe"

#D:\My" "files\svea_laptop\Downloads\SuperTuxKart-dev\stk-code\build\bin\Release\supertuxkart.exe
#Invoke-Expression "& '$path\supertuxkart.exe'"
echo "$path\supertuxkart.exe"
$path = $path -replace ' ','` '
Invoke-Expression "$path\supertuxkart.exe"