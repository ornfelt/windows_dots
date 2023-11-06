if (Test-Path "C:\Users\jonas\OneDrive\Documents\Games\wow") {
	$path = "C:\Users\jonas\OneDrive\Documents\Games\wow"
} elseif (Test-Path "D:\My files\World of Warcraft 3.3.5a") {
	$path = "D:\My files\World of Warcraft 3.3.5a"
} elseif (Test-Path "x") {
	$path = "x"
} else {
	$path = "~/"
}

#cd $path
echo "$path\Wow.exe"

#Invoke-Expression "& '$path\Wow.exe'"
$path = $path -replace ' ','` '
Invoke-Expression "$path\Wow.exe"