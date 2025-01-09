$user_arg = $args[0]

if ($user_arg -ieq "classic") {
    if ($env:wow_classic_dir -and (Test-Path $env:wow_classic_dir)) {
        $path = $env:wow_classic_dir
    } elseif (Test-Path "C:\Users\jonas\OneDrive\Documents\Games\wow_classic") {
		$path = "C:\Users\jonas\OneDrive\Documents\Games\wow_classic"
	} elseif (Test-Path "D:\My files\wow_classic") {
		$path = "D:\My files\wow_classic"
	} elseif (Test-Path "C:\Users\jonas\Downloads\wow_classic") {
		$path = "C:\Users\jonas\Downloads\wow_classic"
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/WoW.exe"

} elseif ($user_arg -ieq "tbc") {
    if ($env:wow_tbc_dir -and (Test-Path $env:wow_tbc_dir)) {
        $path = $env:wow_tbc_dir
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/WoW.exe"

} elseif ($user_arg -ieq "cata") {
    if ($env:wow_cata_dir -and (Test-Path $env:wow_cata_dir)) {
        $path = $env:wow_cata_dir
	} else {
		$path = "~/"
	}

	#cd $path
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/WoW.exe"

} else {
    # wotlk
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
	echo "$path/Wow.exe"

	#Invoke-Expression "& '$path\Wow.exe'"
	$path = $path -replace ' ','` '
	Invoke-Expression "$path/Wow.exe"
}

