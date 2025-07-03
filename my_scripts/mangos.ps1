$server = $args[0]

# MangosZero
if ($server -ieq "0" -or $server -ieq "z") {
	echo "MangosZero chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/server/build/src/mangosd/RelWithDebInfo"
	$altBasePathasePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangoszero/server/build/src/mangosd/RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
    } elseif (Test-Path $altBasePath) {
		$path = $altBasePath
	} else {
		$path = "~/mangoszero/bin"
	}
# Cmangos
} elseif ($server -ieq "c") {
	echo "Cmangos chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-classic/build/bin/x64_RelWithDebInfo"
	$altBasePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/cmangos/mangos-classic/build/bin/x64_RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
    } elseif (Test-Path $altBasePath) {
		$path = $altBasePath
	} else {
		$path = "~/cmangos/run/bin"
	}

} elseif ($server -ieq "tbc") {
	echo "Cmangos tbc chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/mangos-tbc/build/bin/x64_RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
    } else {
        Write-Host "Base path does not exist: $basePath"
        exit 1
    }

# Default to Vmangos
} else {
	echo "Vmangos chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/core/bin/RelWithDebInfo"
	$altBasePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2/C++/vmangos/core/bin/RelWithDebInfo"
	
	if (Test-Path $basePath) {
		$path = $basePath
    } elseif (Test-Path $altBasePath) {
		$path = $altBasePath
	} else {
		$path = "~/vmangos/bin"
	}
}

cd $path

#echo "$path/mangosd.exe"
#Invoke-Expression "$path/realmd.exe;"

echo "$path/realmd.exe; $path/mangosd.exe"
#Invoke-Expression "$path\mangosd.exe"

