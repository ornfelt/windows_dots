$user_arg = $args[0]

if ($user_arg -eq "classic")
{
	if (Test-Path "C:\Users\jonas\OneDrive\Documents\Games\wow_classic") {
		$path = "C:\Users\jonas\OneDrive\Documents\Games\wow_classic"
	} elseif (Test-Path "D:\My files\wow_classic") {
		$path = "D:\My files\wow_classic"
	} elseif (Test-Path "C:\Users\jonas\Downloads\wow_classic") {
		$path = "C:\Users\jonas\Downloads\wow_classic"
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path\Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path\WoW.exe"
}
else
{
	if (Test-Path "C:\Users\jonas\OneDrive\Documents\Games\wow") {
		$path = "C:\Users\jonas\OneDrive\Documents\Games\wow"
	} elseif (Test-Path "D:\My files\World of Warcraft 3.3.5a") {
		$path = "D:\My files\World of Warcraft 3.3.5a"
	} elseif (Test-Path "C:\Users\jonas\Downloads\wow") {
		$path = "C:\Users\jonas\Downloads\wow"
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path\Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path\Wow.exe"
}

