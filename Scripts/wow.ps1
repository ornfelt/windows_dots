$path = "C:\Users\jonas\OneDrive\Documents\Games\wow"

#cd $path
#echo "$path\Wow.exe"

#Invoke-Expression "& '$path\Wow.exe'"
$path = $path -replace ' ','` '
Invoke-Expression "$path\Wow.exe"