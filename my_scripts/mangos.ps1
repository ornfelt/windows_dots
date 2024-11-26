$server = $args[0]

# MangosZero
if ($server -eq "0" -or $server -eq "z") {
	echo "MangosZero chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\mangoszero\server\build\src\mangosd\RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
	} elseif (Test-Path "D:\My files\svea_laptop\mangoszero\server\build\src\mangosd\RelWithDebInfo") {
		$path = "D:\My files\svea_laptop\mangoszero\server\build\src\mangosd\RelWithDebInfo"
	} else {
		$path = "~/mangoszero/bin"
	}
# Cmangos
} elseif ($server -eq "c") {
	echo "Cmangos chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\cmangos\mangos-classic\build\bin\x64_RelWithDebInfo"

	if (Test-Path $basePath) {
		$path = $basePath
	} elseif (Test-Path "D:\My files\svea_laptop\cmangos\mangos-classic\build\bin\x64_RelWithDebInfo") {
		$path = "D:\My files\svea_laptop\cmangos\mangos-classic\build\bin\x64_RelWithDebInfo"
	} else {
		$path = "~/cmangos/run/bin"
	}
# Default to Vmangos
} else {
	echo "Vmangos chosen..."
	$basePath = Join-Path -Path $env:code_root_dir -ChildPath "Code2\C++\vmangos\core\bin\RelWithDebInfo"
	
	if (Test-Path $basePath) {
		$path = $basePath
	} elseif (Test-Path "D:\My files\svea_laptop\vmangos\core\bin\RelWithDebInfo") {
		$path = "D:\My files\svea_laptop\vmangos\core\bin\RelWithDebInfo"
	} else {
		$path = "~/vmangos/bin"
	}
}

cd $path

#echo "$path\mangosd.exe"
#Invoke-Expression "$path\realmd.exe;"

echo "$path\realmd.exe; $path\mangosd.exe"
#Invoke-Expression "$path\mangosd.exe"

